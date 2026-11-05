export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[]

export type BusinessRole = 'owner' | 'admin' | 'cashier' | 'viewer'
export type MemberRole = 'admin' | 'cashier' | 'viewer'
export type TransactionType = 'income' | 'expense'
export type DebtType = 'receivable' | 'payable'
export type PlanType = 'free' | 'premium' | 'business'
export type SubscriptionStatus = 'active' | 'past_due' | 'cancelled' | 'expired'

export interface Database {
  public: {
    Tables: {
      business_profiles: {
        Row: {
          id: string
          user_id: string
          business_name: string
          owner_name: string
          business_type: string
          phone: string
          address: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id?: string
          user_id: string
          business_name: string
          owner_name?: string
          business_type?: string
          phone?: string
          address?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          business_name?: string
          owner_name?: string
          business_type?: string
          phone?: string
          address?: string
          created_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      business_members: {
        Row: {
          business_id: string
          member_user_id: string
          role: MemberRole
          created_by: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          business_id: string
          member_user_id: string
          role: MemberRole
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          business_id?: string
          member_user_id?: string
          role?: MemberRole
          created_by?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      business_plans: {
        Row: {
          plan: PlanType
          max_members: number
          monthly_transaction_limit: number | null
          attachments_enabled: boolean
          price_amount: number
          currency: string
          billing_period_days: number
        }
        Insert: {
          plan: PlanType
          max_members?: number
          monthly_transaction_limit?: number | null
          attachments_enabled?: boolean
          price_amount?: number
          currency?: string
          billing_period_days?: number
        }
        Update: {
          plan?: PlanType
          max_members?: number
          monthly_transaction_limit?: number | null
          attachments_enabled?: boolean
          price_amount?: number
          currency?: string
          billing_period_days?: number
        }
        Relationships: []
      }
      business_subscriptions: {
        Row: {
          business_id: string
          plan: PlanType
          status: SubscriptionStatus
          current_period_end: string | null
          provider: string
          provider_reference: string | null
          updated_by: string | null
          created_at: string
          updated_at: string
        }
        Insert: {
          business_id: string
          plan: PlanType
          status: SubscriptionStatus
          current_period_end?: string | null
          provider?: string
          provider_reference?: string | null
          updated_by?: string | null
          created_at?: string
          updated_at?: string
        }
        Update: {
          business_id?: string
          plan?: PlanType
          status?: SubscriptionStatus
          current_period_end?: string | null
          provider?: string
          provider_reference?: string | null
          updated_by?: string | null
          created_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      transactions: {
        Row: {
          id: string
          user_id: string
          created_by: string | null
          type: TransactionType
          amount: number
          category_id: string
          payment_method_id: string
          transaction_date: string
          description: string
          attachment_url: string | null
          created_at: string
          updated_at: string
          deleted_at: string | null
        }
        Insert: {
          id: string
          user_id: string
          created_by?: string | null
          type: TransactionType
          amount: number
          category_id: string
          payment_method_id: string
          transaction_date: string
          description?: string
          attachment_url?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Update: {
          id?: string
          user_id?: string
          created_by?: string | null
          type?: TransactionType
          amount?: number
          category_id?: string
          payment_method_id?: string
          transaction_date?: string
          description?: string
          attachment_url?: string | null
          created_at?: string
          updated_at?: string
          deleted_at?: string | null
        }
        Relationships: []
      }
      debts: {
        Row: {
          id: string
          user_id: string
          created_by: string | null
          type: DebtType
          contact_name: string
          phone: string
          amount: number
          paid_amount: number
          transaction_date: string
          due_date: string
          note: string
          created_at: string
          updated_at: string
        }
        Insert: {
          id: string
          user_id: string
          created_by?: string | null
          type: DebtType
          contact_name: string
          phone?: string
          amount: number
          paid_amount?: number
          transaction_date: string
          due_date: string
          note?: string
          created_at?: string
          updated_at?: string
        }
        Update: {
          id?: string
          user_id?: string
          created_by?: string | null
          type?: DebtType
          contact_name?: string
          phone?: string
          amount?: number
          paid_amount?: number
          transaction_date?: string
          due_date?: string
          note?: string
          created_at?: string
          updated_at?: string
        }
        Relationships: []
      }
      debt_payments: {
        Row: {
          id: string
          debt_id: string
          user_id: string
          created_by: string | null
          amount: number
          payment_date: string
          note: string
          ledger_transaction_id: string
          created_at: string
        }
        Insert: {
          id: string
          debt_id: string
          user_id: string
          created_by?: string | null
          amount: number
          payment_date: string
          note?: string
          ledger_transaction_id: string
          created_at?: string
        }
        Update: {
          id?: string
          debt_id?: string
          user_id?: string
          created_by?: string | null
          amount?: number
          payment_date?: string
          note?: string
          ledger_transaction_id?: string
          created_at?: string
        }
        Relationships: []
      }
    }
    Views: {
      [_ in never]: never
    }
    Functions: {
      get_my_business_access: {
        Args: Record<PropertyKey, never>
        Returns: GetMyBusinessAccessResult
      }
      update_business_profile: {
        Args: {
          p_business_name: string
          p_owner_name: string
          p_business_type: string
          p_phone: string
          p_address: string
        }
        Returns: void
      }
      list_business_members: {
        Args: Record<PropertyKey, never>
        Returns: {
          member_user_id: string
          email: string
          role: MemberRole
          created_at: string
        }[]
      }
      add_business_member: {
        Args: {
          p_email: string
          p_role: MemberRole
        }
        Returns: string
      }
      update_business_member_role: {
        Args: {
          p_member_user_id: string
          p_role: MemberRole
        }
        Returns: void
      }
      remove_business_member: {
        Args: {
          p_member_user_id: string
        }
        Returns: void
      }
      sync_transaction: {
        Args: {
          p_transaction: Json
          p_operation: 'create' | 'update' | 'delete'
          p_idempotency_key: string
          p_expected_updated_at?: string | null
        }
        Returns: {
          status: 'synced' | 'conflict'
          transaction?: Database['public']['Tables']['transactions']['Row']
          remote?: Database['public']['Tables']['transactions']['Row'] | null
        }
      }
      record_debt_payment: {
        Args: {
          p_payment_id: string
          p_debt_id: string
          p_amount: number
          p_payment_date: string
          p_note: string
          p_ledger_transaction_id: string
          p_ledger_description: string
        }
        Returns: string
      }
    }
    Enums: {
      [_ in never]: never
    }
    CompositeTypes: {
      [_ in never]: never
    }
  }
}

export interface GetMyBusinessAccessResult {
  business_id: string
  role: BusinessRole
  plan: PlanType
  subscription_status: SubscriptionStatus
  current_period_end: string | null
  members_used: number
  max_members: number
  transactions_used: number
  monthly_transaction_limit: number | null
  attachments_enabled: boolean
  can_manage_settings: boolean
  can_manage_members: boolean
  can_create_transactions: boolean
}
