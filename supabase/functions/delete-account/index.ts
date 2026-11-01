import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return Response.json(
      { error: 'Method not allowed' },
      { status: 405, headers: corsHeaders },
    );
  }

  const authorization = request.headers.get('Authorization') ?? '';
  const token = authorization.replace(/^Bearer\s+/i, '');
  if (!token || token === authorization) {
    return Response.json(
      { error: 'Authentication required' },
      { status: 401, headers: corsHeaders },
    );
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const publishableKey = Deno.env.get('SUPABASE_ANON_KEY');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!supabaseUrl || !publishableKey || !serviceRoleKey) {
    return Response.json(
      { error: 'Server configuration unavailable' },
      { status: 500, headers: corsHeaders },
    );
  }

  const userClient = createClient(supabaseUrl, publishableKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  const { data: userData, error: userError } = await userClient.auth.getUser(
    token,
  );
  if (userError || !userData.user) {
    return Response.json(
      { error: 'Invalid session' },
      { status: 401, headers: corsHeaders },
    );
  }

  const { data: access, error: accessError } = await userClient.rpc(
    'get_my_business_access',
  );
  if (accessError || !access?.business_id) {
    return Response.json(
      { error: 'Business context unavailable' },
      { status: 500, headers: corsHeaders },
    );
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });
  if (access.role === 'owner') {
    try {
      const attachmentPaths = await listStorageFiles(
        adminClient,
        access.business_id,
      );
      for (let index = 0; index < attachmentPaths.length; index += 100) {
        const { error } = await adminClient.storage
          .from('transaction-attachments')
          .remove(attachmentPaths.slice(index, index + 100));
        if (error) throw error;
      }
    } catch {
      return Response.json(
        { error: 'Business attachment cleanup failed' },
        { status: 500, headers: corsHeaders },
      );
    }
  }

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(
    userData.user.id,
  );
  if (deleteError) {
    return Response.json(
      { error: 'Account deletion failed' },
      { status: 500, headers: corsHeaders },
    );
  }

  return Response.json({ deleted: true }, { headers: corsHeaders });
});

async function listStorageFiles(
  client: ReturnType<typeof createClient>,
  folder: string,
): Promise<string[]> {
  const paths: string[] = [];
  let offset = 0;
  while (true) {
    const { data, error } = await client.storage
      .from('transaction-attachments')
      .list(folder, { limit: 1000, offset });
    if (error) throw error;
    for (const entry of data) {
      const path = `${folder}/${entry.name}`;
      if (entry.id == null) {
        paths.push(...await listStorageFiles(client, path));
      } else {
        paths.push(path);
      }
    }
    if (data.length < 1000) break;
    offset += data.length;
  }
  return paths;
}