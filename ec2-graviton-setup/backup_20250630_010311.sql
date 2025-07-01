--
-- PostgreSQL database dump
--

-- Dumped from database version 15.13
-- Dumped by pg_dump version 15.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_supervisor_id_fkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_role_id_fkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_department_id_fkey;
ALTER TABLE IF EXISTS ONLY public.suppliers DROP CONSTRAINT IF EXISTS suppliers_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.role_permissions DROP CONSTRAINT IF EXISTS role_permissions_role_id_fkey;
ALTER TABLE IF EXISTS ONLY public.role_permissions DROP CONSTRAINT IF EXISTS role_permissions_permission_id_fkey;
ALTER TABLE IF EXISTS ONLY public.projects_trades DROP CONSTRAINT IF EXISTS projects_trades_trade_id_fkey;
ALTER TABLE IF EXISTS ONLY public.projects_trades DROP CONSTRAINT IF EXISTS projects_trades_project_id_fkey;
ALTER TABLE IF EXISTS ONLY public.projects_trades DROP CONSTRAINT IF EXISTS projects_trades_engineer_id_fkey;
ALTER TABLE IF EXISTS ONLY public.project_companies DROP CONSTRAINT IF EXISTS project_companies_project_id_fkey;
ALTER TABLE IF EXISTS ONLY public.project_companies DROP CONSTRAINT IF EXISTS project_companies_company_id_fkey;
ALTER TABLE IF EXISTS ONLY public.project_approvals DROP CONSTRAINT IF EXISTS project_approvals_project_id_fkey;
ALTER TABLE IF EXISTS ONLY public.project_approvals DROP CONSTRAINT IF EXISTS project_approvals_approver_id_fkey;
ALTER TABLE IF EXISTS ONLY public.project_approvals DROP CONSTRAINT IF EXISTS project_approvals_approval_type_code_fkey;
ALTER TABLE IF EXISTS ONLY public.note_badges DROP CONSTRAINT IF EXISTS note_badges_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.department_association_approvals DROP CONSTRAINT IF EXISTS department_association_approvals_approver_id_fkey;
ALTER TABLE IF EXISTS ONLY public.department_association_approvals DROP CONSTRAINT IF EXISTS department_association_approvals_approval_type_code_fkey;
ALTER TABLE IF EXISTS ONLY public.department_approvals DROP CONSTRAINT IF EXISTS department_approvals_department_id_fkey;
ALTER TABLE IF EXISTS ONLY public.department_approvals DROP CONSTRAINT IF EXISTS department_approvals_approver_id_fkey;
ALTER TABLE IF EXISTS ONLY public.department_approvals DROP CONSTRAINT IF EXISTS department_approvals_approval_type_code_fkey;
ALTER TABLE IF EXISTS ONLY public.comment_badges DROP CONSTRAINT IF EXISTS comment_badges_user_id_fkey;
ALTER TABLE IF EXISTS ONLY public.attachment_badges DROP CONSTRAINT IF EXISTS attachment_badges_user_id_fkey;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.rs_payment_requests;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.rs_payment_request_approvers;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.requisitions;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.requisition_return_histories;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.requisition_payment_histories;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.requisition_order_histories;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.requisition_item_lists;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.requisition_item_histories;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.requisition_delivery_histories;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.requisition_canvass_histories;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.requisition_badges;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.requisition_approvers;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.purchase_orders;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.purchase_order_items;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.purchase_order_cancelled_items;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.purchase_order_approvers;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.notifications;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.notes;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.non_requisitions;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.non_requisition_items;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.non_requisition_histories;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.non_requisition_approvers;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.invoice_reports;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.invoice_report_histories;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.histories;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.force_close_logs;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.delivery_receipts;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.delivery_receipt_items_history;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.delivery_receipt_items;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.delivery_receipt_invoices;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.comments;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.canvass_requisitions;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.canvass_items;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.canvass_item_suppliers;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.canvass_approvers;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.audit_logs;
DROP TRIGGER IF EXISTS ts_insert_blocker ON public.attachments;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_73;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_72;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_71;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_70;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_69;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_68;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_67;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_66;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_65;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_64;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_63;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_62;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_61;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_60;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_59;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_58;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_57;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_56;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_55;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_54;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_53;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_52;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_51;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_50;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_49;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_48;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_47;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_46;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_45;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_44;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_43;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_42;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_41;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_40;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_39;
DROP TRIGGER IF EXISTS ts_insert_blocker ON _timescaledb_internal._compressed_hypertable_38;
DROP INDEX IF EXISTS public.users_supervisor_id_idx;
DROP INDEX IF EXISTS public.unique_project_trade_engineer;
DROP INDEX IF EXISTS public.unique_canvass_role;
DROP INDEX IF EXISTS public.unique_canvass_requisition_item_with_time;
DROP INDEX IF EXISTS public.unique_canvass_item_supplier_with_time;
DROP INDEX IF EXISTS public.rs_payment_requests_created_at_idx;
DROP INDEX IF EXISTS public.rs_payment_request_approvers_created_at_idx;
DROP INDEX IF EXISTS public.role_permissions_role_id_permission_id;
DROP INDEX IF EXISTS public.requisitions_status_index;
DROP INDEX IF EXISTS public.requisitions_created_at_idx;
DROP INDEX IF EXISTS public.requisition_return_histories_created_at_idx;
DROP INDEX IF EXISTS public.requisition_payment_histories_created_at_idx;
DROP INDEX IF EXISTS public.requisition_order_histories_created_at_idx;
DROP INDEX IF EXISTS public.requisition_number_index;
DROP INDEX IF EXISTS public.requisition_item_lists_created_at_idx;
DROP INDEX IF EXISTS public.requisition_item_histories_created_at_idx;
DROP INDEX IF EXISTS public.requisition_delivery_histories_created_at_idx;
DROP INDEX IF EXISTS public.requisition_canvass_histories_requisition_item_list_id_supplier;
DROP INDEX IF EXISTS public.requisition_canvass_histories_created_at_idx;
DROP INDEX IF EXISTS public.requisition_badges_requisition_id;
DROP INDEX IF EXISTS public.requisition_badges_created_at_idx;
DROP INDEX IF EXISTS public.requisition_approvers_created_at_idx;
DROP INDEX IF EXISTS public.purchase_orders_supplier_id_supplier_type;
DROP INDEX IF EXISTS public.purchase_orders_status;
DROP INDEX IF EXISTS public.purchase_orders_requisition_id;
DROP INDEX IF EXISTS public.purchase_orders_po_number;
DROP INDEX IF EXISTS public.purchase_orders_po_letter;
DROP INDEX IF EXISTS public.purchase_orders_created_at_idx;
DROP INDEX IF EXISTS public.purchase_orders_canvass_requisition_id;
DROP INDEX IF EXISTS public.purchase_order_items_requisition_item_list_id;
DROP INDEX IF EXISTS public.purchase_order_items_purchase_order_id;
DROP INDEX IF EXISTS public.purchase_order_items_created_at_idx;
DROP INDEX IF EXISTS public.purchase_order_items_canvass_item_supplier_id;
DROP INDEX IF EXISTS public.purchase_order_items_canvass_item_id;
DROP INDEX IF EXISTS public.purchase_order_cancelled_items_created_at_idx;
DROP INDEX IF EXISTS public.purchase_order_approvers_user_id;
DROP INDEX IF EXISTS public.purchase_order_approvers_status;
DROP INDEX IF EXISTS public.purchase_order_approvers_role_id;
DROP INDEX IF EXISTS public.purchase_order_approvers_purchase_order_id;
DROP INDEX IF EXISTS public.purchase_order_approvers_level;
DROP INDEX IF EXISTS public.purchase_order_approvers_created_at_idx;
DROP INDEX IF EXISTS public.purchase_order_approvers_alt_approver_id;
DROP INDEX IF EXISTS public.projects_trades_trade_id;
DROP INDEX IF EXISTS public.projects_trades_project_id;
DROP INDEX IF EXISTS public.projects_trades_engineer_id;
DROP INDEX IF EXISTS public.projects_name;
DROP INDEX IF EXISTS public.projects_company_id;
DROP INDEX IF EXISTS public.projects_code;
DROP INDEX IF EXISTS public.project_companies_unique;
DROP INDEX IF EXISTS public.project_approvals_project_id;
DROP INDEX IF EXISTS public.project_approvals_proj_type_idx;
DROP INDEX IF EXISTS public.project_approvals_level;
DROP INDEX IF EXISTS public.project_approvals_approver_id;
DROP INDEX IF EXISTS public.project_approvals_approval_type_code;
DROP INDEX IF EXISTS public.po_cancelled_items_supplier_composite_index;
DROP INDEX IF EXISTS public.po_cancelled_items_requisition_id_index;
DROP INDEX IF EXISTS public.po_cancelled_items_requisition_composite_index;
DROP INDEX IF EXISTS public.po_cancelled_items_po_id_index;
DROP INDEX IF EXISTS public.po_cancelled_items_canvass_item_id_index;
DROP INDEX IF EXISTS public.permissions_module_action;
DROP INDEX IF EXISTS public.notifications_type_idx;
DROP INDEX IF EXISTS public.notifications_recipient_user_ids_idx;
DROP INDEX IF EXISTS public.notifications_recipient_role_id_idx;
DROP INDEX IF EXISTS public.notifications_created_at_idx;
DROP INDEX IF EXISTS public.notes_model_model_id;
DROP INDEX IF EXISTS public.notes_created_at;
DROP INDEX IF EXISTS public.non_requisitions_status_index;
DROP INDEX IF EXISTS public.non_requisitions_non_rs_number_index;
DROP INDEX IF EXISTS public.non_requisitions_non_rs_letter_index;
DROP INDEX IF EXISTS public.non_requisitions_invoice_no_index;
DROP INDEX IF EXISTS public.non_requisitions_draft_non_rs_number_index;
DROP INDEX IF EXISTS public.non_requisitions_created_by_index;
DROP INDEX IF EXISTS public.non_requisitions_created_at_idx;
DROP INDEX IF EXISTS public.non_requisitions_charge_to_index;
DROP INDEX IF EXISTS public.non_requisition_items_non_requisition_id_index;
DROP INDEX IF EXISTS public.non_requisition_items_name_index;
DROP INDEX IF EXISTS public.non_requisition_items_created_at_idx;
DROP INDEX IF EXISTS public.non_requisition_histories_updated_at_index;
DROP INDEX IF EXISTS public.non_requisition_histories_status_index;
DROP INDEX IF EXISTS public.non_requisition_histories_non_requisition_id_index;
DROP INDEX IF EXISTS public.non_requisition_histories_created_at_idx;
DROP INDEX IF EXISTS public.non_requisition_histories_approver_id_index;
DROP INDEX IF EXISTS public.non_requisition_approvers_user_id_index;
DROP INDEX IF EXISTS public.non_requisition_approvers_status_index;
DROP INDEX IF EXISTS public.non_requisition_approvers_role_id_index;
DROP INDEX IF EXISTS public.non_requisition_approvers_non_requisition_id_index;
DROP INDEX IF EXISTS public.non_requisition_approvers_created_at_idx;
DROP INDEX IF EXISTS public.invoice_reports_created_at_idx;
DROP INDEX IF EXISTS public.invoice_reports_company_code_ir_number_idx;
DROP INDEX IF EXISTS public.invoice_reports_company_code_ir_draft_number_idx;
DROP INDEX IF EXISTS public.invoice_report_histories_created_at_idx;
DROP INDEX IF EXISTS public.idx_rs_payment_requests_cancelled_by;
DROP INDEX IF EXISTS public.idx_rs_payment_requests_cancelled_at;
DROP INDEX IF EXISTS public.idx_requisitions_force_closed_by;
DROP INDEX IF EXISTS public.idx_requisitions_force_closed_at;
DROP INDEX IF EXISTS public.idx_requisitions_force_close_scenario;
DROP INDEX IF EXISTS public.idx_projects_trades_project_trade;
DROP INDEX IF EXISTS public.idx_invoice_reports_cancelled_by;
DROP INDEX IF EXISTS public.idx_invoice_reports_cancelled_at;
DROP INDEX IF EXISTS public.idx_force_close_logs_user_id;
DROP INDEX IF EXISTS public.idx_force_close_logs_scenario_type;
DROP INDEX IF EXISTS public.idx_force_close_logs_requisition_id;
DROP INDEX IF EXISTS public.idx_force_close_logs_created_at;
DROP INDEX IF EXISTS public.idx_delivery_receipts_cancelled_by;
DROP INDEX IF EXISTS public.idx_delivery_receipts_cancelled_at;
DROP INDEX IF EXISTS public.idx_canvass_requisitions_cancelled_by;
DROP INDEX IF EXISTS public.idx_canvass_requisitions_cancelled_at;
DROP INDEX IF EXISTS public.idx_canvass_items_requisition_id;
DROP INDEX IF EXISTS public.idx_canvass_items_req_id_status;
DROP INDEX IF EXISTS public.histories_rs_letter_rs_number_company_id_index;
DROP INDEX IF EXISTS public.histories_project_id;
DROP INDEX IF EXISTS public.histories_item_id_type_index;
DROP INDEX IF EXISTS public.histories_item_id_idx;
DROP INDEX IF EXISTS public.histories_department_id;
DROP INDEX IF EXISTS public.histories_created_at_idx;
DROP INDEX IF EXISTS public.histories_company_id;
DROP INDEX IF EXISTS public.draft_requisition_number_index;
DROP INDEX IF EXISTS public.departments_name;
DROP INDEX IF EXISTS public.department_association_approvals_level;
DROP INDEX IF EXISTS public.department_association_approvals_area_code;
DROP INDEX IF EXISTS public.department_association_approvals_approver_id;
DROP INDEX IF EXISTS public.department_association_approvals_approval_type_code;
DROP INDEX IF EXISTS public.department_approvals_dept_type_idx;
DROP INDEX IF EXISTS public.delivery_receipts_req_id_delivery_status_index;
DROP INDEX IF EXISTS public.delivery_receipts_created_at_idx;
DROP INDEX IF EXISTS public.delivery_receipt_items_history_created_at_idx;
DROP INDEX IF EXISTS public.delivery_receipt_items_created_at_idx;
DROP INDEX IF EXISTS public.delivery_receipt_invoices_created_at_idx;
DROP INDEX IF EXISTS public.comments_created_at_idx;
DROP INDEX IF EXISTS public.comment_badges_user_id_comment_id;
DROP INDEX IF EXISTS public.canvass_requisitions_status;
DROP INDEX IF EXISTS public.canvass_requisitions_requisition_id;
DROP INDEX IF EXISTS public.canvass_requisitions_created_at_idx;
DROP INDEX IF EXISTS public.canvass_items_requisition_item_list_id;
DROP INDEX IF EXISTS public.canvass_items_created_at_idx;
DROP INDEX IF EXISTS public.canvass_items_canvass_requisition_id;
DROP INDEX IF EXISTS public.canvass_item_suppliers_supplier_id;
DROP INDEX IF EXISTS public.canvass_item_suppliers_order;
DROP INDEX IF EXISTS public.canvass_item_suppliers_created_at_idx;
DROP INDEX IF EXISTS public.canvass_item_suppliers_canvass_item_id;
DROP INDEX IF EXISTS public.canvass_approvers_user_id;
DROP INDEX IF EXISTS public.canvass_approvers_role_id;
DROP INDEX IF EXISTS public.canvass_approvers_level;
DROP INDEX IF EXISTS public.canvass_approvers_created_at_idx;
DROP INDEX IF EXISTS public.canvass_approvers_canvass_requisition_id;
DROP INDEX IF EXISTS public.canvass_approver;
DROP INDEX IF EXISTS public.audit_logs_module;
DROP INDEX IF EXISTS public.audit_logs_created_at;
DROP INDEX IF EXISTS public.audit_logs_action_type;
DROP INDEX IF EXISTS public.attachments_model_model_id_index;
DROP INDEX IF EXISTS public.attachments_created_at_idx;
DROP INDEX IF EXISTS public.attachment_badges_user_id_attachment_id;
DROP INDEX IF EXISTS public.association_areas_code_unique;
DROP INDEX IF EXISTS public.approval_types_code;
ALTER TABLE IF EXISTS ONLY public.warranties DROP CONSTRAINT IF EXISTS warranties_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_username_key;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_pkey;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_email_key1;
ALTER TABLE IF EXISTS ONLY public.users DROP CONSTRAINT IF EXISTS users_email_key;
ALTER TABLE IF EXISTS ONLY public.note_badges DROP CONSTRAINT IF EXISTS unique_user_note_constraint;
ALTER TABLE IF EXISTS ONLY public.comment_badges DROP CONSTRAINT IF EXISTS unique_user_comment_constraint;
ALTER TABLE IF EXISTS ONLY public.attachment_badges DROP CONSTRAINT IF EXISTS unique_user_attachment_constraint;
ALTER TABLE IF EXISTS ONLY public.steelbars DROP CONSTRAINT IF EXISTS unique_grade_diameter_length_ofm_acctcd;
ALTER TABLE IF EXISTS ONLY public.departments DROP CONSTRAINT IF EXISTS unique_department_code_per_department;
ALTER TABLE IF EXISTS ONLY public.trades DROP CONSTRAINT IF EXISTS trades_trade_code_key;
ALTER TABLE IF EXISTS ONLY public.trades DROP CONSTRAINT IF EXISTS trades_pkey;
ALTER TABLE IF EXISTS ONLY public.tom_items DROP CONSTRAINT IF EXISTS tom_items_pkey;
ALTER TABLE IF EXISTS ONLY public.timescaledb_migration_status DROP CONSTRAINT IF EXISTS timescaledb_migration_status_table_name_key;
ALTER TABLE IF EXISTS ONLY public.timescaledb_migration_status DROP CONSTRAINT IF EXISTS timescaledb_migration_status_pkey;
ALTER TABLE IF EXISTS ONLY public.syncs DROP CONSTRAINT IF EXISTS syncs_pkey;
ALTER TABLE IF EXISTS ONLY public.syncs DROP CONSTRAINT IF EXISTS syncs_model_key;
ALTER TABLE IF EXISTS ONLY public.suppliers DROP CONSTRAINT IF EXISTS suppliers_pkey;
ALTER TABLE IF EXISTS ONLY public.suppliers DROP CONSTRAINT IF EXISTS suppliers_pay_code_key;
ALTER TABLE IF EXISTS ONLY public.steelbars DROP CONSTRAINT IF EXISTS steelbars_pkey;
ALTER TABLE IF EXISTS ONLY public.rs_payment_requests DROP CONSTRAINT IF EXISTS rs_payment_requests_pkey;
ALTER TABLE IF EXISTS ONLY public.rs_payment_request_approvers DROP CONSTRAINT IF EXISTS rs_payment_request_approvers_pkey;
ALTER TABLE IF EXISTS ONLY public.roles DROP CONSTRAINT IF EXISTS roles_pkey;
ALTER TABLE IF EXISTS ONLY public.roles DROP CONSTRAINT IF EXISTS roles_name_key;
ALTER TABLE IF EXISTS ONLY public.role_permissions DROP CONSTRAINT IF EXISTS role_permissions_pkey;
ALTER TABLE IF EXISTS ONLY public.requisitions DROP CONSTRAINT IF EXISTS requisitions_pkey;
ALTER TABLE IF EXISTS ONLY public.requisition_return_histories DROP CONSTRAINT IF EXISTS requisition_return_histories_pkey;
ALTER TABLE IF EXISTS ONLY public.requisition_payment_histories DROP CONSTRAINT IF EXISTS requisition_payment_histories_pkey;
ALTER TABLE IF EXISTS ONLY public.requisition_order_histories DROP CONSTRAINT IF EXISTS requisition_order_histories_pkey;
ALTER TABLE IF EXISTS ONLY public.requisition_item_lists DROP CONSTRAINT IF EXISTS requisition_item_lists_pkey;
ALTER TABLE IF EXISTS ONLY public.requisition_item_histories DROP CONSTRAINT IF EXISTS requisition_item_histories_pkey;
ALTER TABLE IF EXISTS ONLY public.requisition_delivery_histories DROP CONSTRAINT IF EXISTS requisition_delivery_histories_pkey;
ALTER TABLE IF EXISTS ONLY public.requisition_canvass_histories DROP CONSTRAINT IF EXISTS requisition_canvass_histories_pkey;
ALTER TABLE IF EXISTS ONLY public.requisition_badges DROP CONSTRAINT IF EXISTS requisition_badges_pkey;
ALTER TABLE IF EXISTS ONLY public.requisition_approvers DROP CONSTRAINT IF EXISTS requisition_approvers_pkey;
ALTER TABLE IF EXISTS ONLY public.purchase_orders DROP CONSTRAINT IF EXISTS purchase_orders_pkey;
ALTER TABLE IF EXISTS ONLY public.purchase_order_items DROP CONSTRAINT IF EXISTS purchase_order_items_pkey;
ALTER TABLE IF EXISTS ONLY public.purchase_order_cancelled_items DROP CONSTRAINT IF EXISTS purchase_order_cancelled_items_pkey;
ALTER TABLE IF EXISTS ONLY public.purchase_order_approvers DROP CONSTRAINT IF EXISTS purchase_order_approvers_pkey;
ALTER TABLE IF EXISTS ONLY public.prs_timescaledb_status DROP CONSTRAINT IF EXISTS prs_timescaledb_status_table_name_key;
ALTER TABLE IF EXISTS ONLY public.prs_timescaledb_status DROP CONSTRAINT IF EXISTS prs_timescaledb_status_pkey;
ALTER TABLE IF EXISTS ONLY public.projects_trades DROP CONSTRAINT IF EXISTS projects_trades_pkey;
ALTER TABLE IF EXISTS ONLY public.projects DROP CONSTRAINT IF EXISTS projects_pkey;
ALTER TABLE IF EXISTS ONLY public.projects DROP CONSTRAINT IF EXISTS projects_code_key;
ALTER TABLE IF EXISTS ONLY public.project_companies DROP CONSTRAINT IF EXISTS project_companies_pkey;
ALTER TABLE IF EXISTS ONLY public.project_approvals DROP CONSTRAINT IF EXISTS project_approvals_pkey;
ALTER TABLE IF EXISTS ONLY public.permissions DROP CONSTRAINT IF EXISTS permissions_pkey;
ALTER TABLE IF EXISTS ONLY public.ofm_list_items DROP CONSTRAINT IF EXISTS ofm_list_items_pkey;
ALTER TABLE IF EXISTS ONLY public.ofm_item_lists DROP CONSTRAINT IF EXISTS ofm_item_lists_pkey;
ALTER TABLE IF EXISTS ONLY public.ofm_item_lists DROP CONSTRAINT IF EXISTS ofm_item_lists_list_name_key;
ALTER TABLE IF EXISTS ONLY public.notifications DROP CONSTRAINT IF EXISTS notifications_pkey;
ALTER TABLE IF EXISTS ONLY public.notes DROP CONSTRAINT IF EXISTS notes_pkey;
ALTER TABLE IF EXISTS ONLY public.note_badges DROP CONSTRAINT IF EXISTS note_badges_pkey;
ALTER TABLE IF EXISTS ONLY public.non_requisitions DROP CONSTRAINT IF EXISTS non_requisitions_pkey;
ALTER TABLE IF EXISTS ONLY public.non_requisition_items DROP CONSTRAINT IF EXISTS non_requisition_items_pkey;
ALTER TABLE IF EXISTS ONLY public.non_requisition_histories DROP CONSTRAINT IF EXISTS non_requisition_histories_pkey;
ALTER TABLE IF EXISTS ONLY public.non_requisition_approvers DROP CONSTRAINT IF EXISTS non_requisition_approvers_pkey;
ALTER TABLE IF EXISTS ONLY public.non_ofm_items DROP CONSTRAINT IF EXISTS non_ofm_items_pkey;
ALTER TABLE IF EXISTS ONLY public.non_ofm_items DROP CONSTRAINT IF EXISTS non_ofm_items_item_name_key1;
ALTER TABLE IF EXISTS ONLY public.non_ofm_items DROP CONSTRAINT IF EXISTS non_ofm_items_item_name_key;
ALTER TABLE IF EXISTS ONLY public.non_ofm_items DROP CONSTRAINT IF EXISTS non_ofm_items_acct_cd_key;
ALTER TABLE IF EXISTS ONLY public.leaves DROP CONSTRAINT IF EXISTS leaves_pkey;
ALTER TABLE IF EXISTS ONLY public.items DROP CONSTRAINT IF EXISTS items_pkey;
ALTER TABLE IF EXISTS ONLY public.items DROP CONSTRAINT IF EXISTS items_item_cd_key;
ALTER TABLE IF EXISTS ONLY public.invoice_reports DROP CONSTRAINT IF EXISTS invoice_reports_pkey;
ALTER TABLE IF EXISTS ONLY public.invoice_report_histories DROP CONSTRAINT IF EXISTS invoice_report_histories_pkey;
ALTER TABLE IF EXISTS ONLY public.histories DROP CONSTRAINT IF EXISTS histories_pkey;
ALTER TABLE IF EXISTS ONLY public.gate_passes DROP CONSTRAINT IF EXISTS gate_passes_pkey;
ALTER TABLE IF EXISTS ONLY public.force_close_logs DROP CONSTRAINT IF EXISTS force_close_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.departments DROP CONSTRAINT IF EXISTS departments_pkey;
ALTER TABLE IF EXISTS ONLY public.department_association_approvals DROP CONSTRAINT IF EXISTS department_association_approvals_pkey;
ALTER TABLE IF EXISTS ONLY public.department_approvals DROP CONSTRAINT IF EXISTS department_approvals_pkey;
ALTER TABLE IF EXISTS ONLY public.delivery_receipts DROP CONSTRAINT IF EXISTS delivery_receipts_pkey;
ALTER TABLE IF EXISTS ONLY public.delivery_receipt_items DROP CONSTRAINT IF EXISTS delivery_receipt_items_pkey;
ALTER TABLE IF EXISTS ONLY public.delivery_receipt_items_history DROP CONSTRAINT IF EXISTS delivery_receipt_items_history_pkey;
ALTER TABLE IF EXISTS ONLY public.delivery_receipt_invoices DROP CONSTRAINT IF EXISTS delivery_receipt_invoices_pkey;
ALTER TABLE IF EXISTS ONLY public.companies DROP CONSTRAINT IF EXISTS companies_pkey;
ALTER TABLE IF EXISTS ONLY public.companies DROP CONSTRAINT IF EXISTS companies_code_key1;
ALTER TABLE IF EXISTS ONLY public.companies DROP CONSTRAINT IF EXISTS companies_code_key;
ALTER TABLE IF EXISTS ONLY public.comments DROP CONSTRAINT IF EXISTS comments_pkey;
ALTER TABLE IF EXISTS ONLY public.comment_badges DROP CONSTRAINT IF EXISTS comment_badges_pkey;
ALTER TABLE IF EXISTS ONLY public.canvass_requisitions DROP CONSTRAINT IF EXISTS canvass_requisitions_pkey;
ALTER TABLE IF EXISTS ONLY public.canvass_items DROP CONSTRAINT IF EXISTS canvass_items_pkey;
ALTER TABLE IF EXISTS ONLY public.canvass_item_suppliers DROP CONSTRAINT IF EXISTS canvass_item_suppliers_pkey;
ALTER TABLE IF EXISTS ONLY public.canvass_approvers DROP CONSTRAINT IF EXISTS canvass_approvers_pkey;
ALTER TABLE IF EXISTS ONLY public.audit_logs DROP CONSTRAINT IF EXISTS audit_logs_pkey;
ALTER TABLE IF EXISTS ONLY public.attachments DROP CONSTRAINT IF EXISTS attachments_pkey;
ALTER TABLE IF EXISTS ONLY public.attachment_badges DROP CONSTRAINT IF EXISTS attachment_badges_pkey;
ALTER TABLE IF EXISTS ONLY public.association_areas DROP CONSTRAINT IF EXISTS association_areas_pkey;
ALTER TABLE IF EXISTS ONLY public.association_areas DROP CONSTRAINT IF EXISTS association_areas_code_key;
ALTER TABLE IF EXISTS ONLY public.approval_types DROP CONSTRAINT IF EXISTS approval_types_pkey;
ALTER TABLE IF EXISTS ONLY public.approval_types DROP CONSTRAINT IF EXISTS approval_types_name_key;
ALTER TABLE IF EXISTS ONLY public.approval_types DROP CONSTRAINT IF EXISTS approval_types_code_key;
ALTER TABLE IF EXISTS ONLY public."SequelizeMeta" DROP CONSTRAINT IF EXISTS "SequelizeMeta_pkey";
ALTER TABLE IF EXISTS public.warranties ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.users ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.trades ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.tom_items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.timescaledb_migration_status ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.syncs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.suppliers ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.steelbars ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.rs_payment_requests ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.rs_payment_request_approvers ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.roles ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.role_permissions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.requisitions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.requisition_return_histories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.requisition_payment_histories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.requisition_order_histories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.requisition_item_lists ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.requisition_item_histories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.requisition_delivery_histories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.requisition_canvass_histories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.requisition_badges ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.requisition_approvers ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.purchase_orders ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.purchase_order_items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.purchase_order_cancelled_items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.purchase_order_approvers ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.prs_timescaledb_status ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.projects_trades ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.projects ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.project_companies ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.project_approvals ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.permissions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.ofm_list_items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.ofm_item_lists ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.notifications ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.notes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.note_badges ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.non_requisitions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.non_requisition_items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.non_requisition_histories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.non_requisition_approvers ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.non_ofm_items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.leaves ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.invoice_reports ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.invoice_report_histories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.histories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.gate_passes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.force_close_logs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.departments ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.department_association_approvals ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.department_approvals ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.delivery_receipts ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.delivery_receipt_items_history ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.delivery_receipt_items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.delivery_receipt_invoices ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.companies ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.comments ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.comment_badges ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.canvass_requisitions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.canvass_items ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.canvass_item_suppliers ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.canvass_approvers ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.audit_logs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.attachments ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.attachment_badges ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.association_areas ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.approval_types ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.warranties_id_seq;
DROP TABLE IF EXISTS public.warranties;
DROP VIEW IF EXISTS public.vw_dashboard_requisitions;
DROP SEQUENCE IF EXISTS public.users_id_seq;
DROP TABLE IF EXISTS public.users;
DROP SEQUENCE IF EXISTS public.trades_id_seq;
DROP TABLE IF EXISTS public.trades;
DROP SEQUENCE IF EXISTS public.tom_items_id_seq;
DROP TABLE IF EXISTS public.tom_items;
DROP SEQUENCE IF EXISTS public.timescaledb_migration_status_id_seq;
DROP TABLE IF EXISTS public.timescaledb_migration_status;
DROP SEQUENCE IF EXISTS public.syncs_id_seq;
DROP TABLE IF EXISTS public.syncs;
DROP SEQUENCE IF EXISTS public.suppliers_id_seq;
DROP TABLE IF EXISTS public.suppliers;
DROP SEQUENCE IF EXISTS public.steelbars_id_seq;
DROP TABLE IF EXISTS public.steelbars;
DROP SEQUENCE IF EXISTS public.rs_payment_requests_id_seq;
DROP TABLE IF EXISTS public.rs_payment_requests;
DROP SEQUENCE IF EXISTS public.rs_payment_request_approvers_id_seq;
DROP TABLE IF EXISTS public.rs_payment_request_approvers;
DROP SEQUENCE IF EXISTS public.roles_id_seq;
DROP TABLE IF EXISTS public.roles;
DROP SEQUENCE IF EXISTS public.role_permissions_id_seq;
DROP TABLE IF EXISTS public.role_permissions;
DROP SEQUENCE IF EXISTS public.requisitions_id_seq;
DROP TABLE IF EXISTS public.requisitions;
DROP SEQUENCE IF EXISTS public.requisition_return_histories_id_seq;
DROP TABLE IF EXISTS public.requisition_return_histories;
DROP SEQUENCE IF EXISTS public.requisition_payment_histories_id_seq;
DROP TABLE IF EXISTS public.requisition_payment_histories;
DROP SEQUENCE IF EXISTS public.requisition_order_histories_id_seq;
DROP TABLE IF EXISTS public.requisition_order_histories;
DROP SEQUENCE IF EXISTS public.requisition_item_lists_id_seq;
DROP TABLE IF EXISTS public.requisition_item_lists;
DROP SEQUENCE IF EXISTS public.requisition_item_histories_id_seq;
DROP TABLE IF EXISTS public.requisition_item_histories;
DROP SEQUENCE IF EXISTS public.requisition_delivery_histories_id_seq;
DROP TABLE IF EXISTS public.requisition_delivery_histories;
DROP SEQUENCE IF EXISTS public.requisition_canvass_histories_id_seq;
DROP TABLE IF EXISTS public.requisition_canvass_histories;
DROP SEQUENCE IF EXISTS public.requisition_badges_id_seq;
DROP TABLE IF EXISTS public.requisition_badges;
DROP SEQUENCE IF EXISTS public.requisition_approvers_id_seq;
DROP TABLE IF EXISTS public.requisition_approvers;
DROP SEQUENCE IF EXISTS public.purchase_orders_id_seq;
DROP TABLE IF EXISTS public.purchase_orders;
DROP SEQUENCE IF EXISTS public.purchase_order_items_id_seq;
DROP TABLE IF EXISTS public.purchase_order_items;
DROP SEQUENCE IF EXISTS public.purchase_order_cancelled_items_id_seq;
DROP TABLE IF EXISTS public.purchase_order_cancelled_items;
DROP SEQUENCE IF EXISTS public.purchase_order_approvers_id_seq;
DROP TABLE IF EXISTS public.purchase_order_approvers;
DROP SEQUENCE IF EXISTS public.prs_timescaledb_status_id_seq;
DROP TABLE IF EXISTS public.prs_timescaledb_status;
DROP SEQUENCE IF EXISTS public.projects_trades_id_seq;
DROP TABLE IF EXISTS public.projects_trades;
DROP SEQUENCE IF EXISTS public.projects_id_seq;
DROP TABLE IF EXISTS public.projects;
DROP SEQUENCE IF EXISTS public.project_companies_id_seq;
DROP TABLE IF EXISTS public.project_companies;
DROP SEQUENCE IF EXISTS public.project_approvals_id_seq;
DROP TABLE IF EXISTS public.project_approvals;
DROP SEQUENCE IF EXISTS public.permissions_id_seq;
DROP TABLE IF EXISTS public.permissions;
DROP SEQUENCE IF EXISTS public.ofm_list_items_id_seq;
DROP TABLE IF EXISTS public.ofm_list_items;
DROP SEQUENCE IF EXISTS public.ofm_item_lists_id_seq;
DROP TABLE IF EXISTS public.ofm_item_lists;
DROP SEQUENCE IF EXISTS public.notifications_id_seq;
DROP TABLE IF EXISTS public.notifications;
DROP SEQUENCE IF EXISTS public.notes_id_seq;
DROP TABLE IF EXISTS public.notes;
DROP SEQUENCE IF EXISTS public.note_badges_id_seq;
DROP TABLE IF EXISTS public.note_badges;
DROP SEQUENCE IF EXISTS public.non_requisitions_id_seq;
DROP TABLE IF EXISTS public.non_requisitions;
DROP SEQUENCE IF EXISTS public.non_requisition_items_id_seq;
DROP TABLE IF EXISTS public.non_requisition_items;
DROP SEQUENCE IF EXISTS public.non_requisition_histories_id_seq;
DROP TABLE IF EXISTS public.non_requisition_histories;
DROP SEQUENCE IF EXISTS public.non_requisition_approvers_id_seq;
DROP TABLE IF EXISTS public.non_requisition_approvers;
DROP SEQUENCE IF EXISTS public.non_ofm_items_id_seq;
DROP TABLE IF EXISTS public.non_ofm_items;
DROP SEQUENCE IF EXISTS public.leaves_id_seq;
DROP TABLE IF EXISTS public.leaves;
DROP SEQUENCE IF EXISTS public.items_id_seq;
DROP TABLE IF EXISTS public.items;
DROP SEQUENCE IF EXISTS public.invoice_reports_id_seq;
DROP TABLE IF EXISTS public.invoice_reports;
DROP SEQUENCE IF EXISTS public.invoice_report_histories_id_seq;
DROP TABLE IF EXISTS public.invoice_report_histories;
DROP SEQUENCE IF EXISTS public.histories_id_seq;
DROP TABLE IF EXISTS public.histories;
DROP SEQUENCE IF EXISTS public.gate_passes_id_seq;
DROP TABLE IF EXISTS public.gate_passes;
DROP SEQUENCE IF EXISTS public.force_close_logs_id_seq;
DROP TABLE IF EXISTS public.force_close_logs;
DROP SEQUENCE IF EXISTS public.departments_id_seq;
DROP TABLE IF EXISTS public.departments;
DROP SEQUENCE IF EXISTS public.department_association_approvals_id_seq;
DROP TABLE IF EXISTS public.department_association_approvals;
DROP SEQUENCE IF EXISTS public.department_approvals_id_seq;
DROP TABLE IF EXISTS public.department_approvals;
DROP SEQUENCE IF EXISTS public.delivery_receipts_id_seq;
DROP TABLE IF EXISTS public.delivery_receipts;
DROP SEQUENCE IF EXISTS public.delivery_receipt_items_id_seq;
DROP SEQUENCE IF EXISTS public.delivery_receipt_items_history_id_seq;
DROP TABLE IF EXISTS public.delivery_receipt_items_history;
DROP TABLE IF EXISTS public.delivery_receipt_items;
DROP SEQUENCE IF EXISTS public.delivery_receipt_invoices_id_seq;
DROP TABLE IF EXISTS public.delivery_receipt_invoices;
DROP SEQUENCE IF EXISTS public.companies_id_seq;
DROP TABLE IF EXISTS public.companies;
DROP SEQUENCE IF EXISTS public.comments_id_seq;
DROP TABLE IF EXISTS public.comments;
DROP SEQUENCE IF EXISTS public.comment_badges_id_seq;
DROP TABLE IF EXISTS public.comment_badges;
DROP SEQUENCE IF EXISTS public.canvass_requisitions_id_seq;
DROP TABLE IF EXISTS public.canvass_requisitions;
DROP SEQUENCE IF EXISTS public.canvass_items_id_seq;
DROP TABLE IF EXISTS public.canvass_items;
DROP SEQUENCE IF EXISTS public.canvass_item_suppliers_id_seq;
DROP TABLE IF EXISTS public.canvass_item_suppliers;
DROP SEQUENCE IF EXISTS public.canvass_approvers_id_seq;
DROP TABLE IF EXISTS public.canvass_approvers;
DROP SEQUENCE IF EXISTS public.audit_logs_id_seq;
DROP TABLE IF EXISTS public.audit_logs;
DROP SEQUENCE IF EXISTS public.attachments_id_seq;
DROP TABLE IF EXISTS public.attachments;
DROP SEQUENCE IF EXISTS public.attachment_badges_id_seq;
DROP TABLE IF EXISTS public.attachment_badges;
DROP SEQUENCE IF EXISTS public.association_areas_id_seq;
DROP TABLE IF EXISTS public.association_areas;
DROP SEQUENCE IF EXISTS public.approval_types_id_seq;
DROP TABLE IF EXISTS public.approval_types;
DROP TABLE IF EXISTS public."SequelizeMeta";
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_73;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_72;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_71;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_70;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_69;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_68;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_67;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_66;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_65;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_64;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_63;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_62;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_61;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_60;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_59;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_58;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_57;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_56;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_55;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_54;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_53;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_52;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_51;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_50;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_49;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_48;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_47;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_46;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_45;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_44;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_43;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_42;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_41;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_40;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_39;
DROP TABLE IF EXISTS _timescaledb_internal._compressed_hypertable_38;
DROP TYPE IF EXISTS public.enum_users_status;
DROP TYPE IF EXISTS public.enum_trades_category;
DROP TYPE IF EXISTS public.enum_requisitions_category;
DROP TYPE IF EXISTS public.enum_purchase_order_cancelled_items_supplier_type;
DROP TYPE IF EXISTS public.enum_non_requisitions_group_discount_type;
DROP TYPE IF EXISTS public.enum_non_requisition_items_discount_type;
DROP TYPE IF EXISTS public.enum_companies_category;
DROP TYPE IF EXISTS public.enum_canvass_item_suppliers_supplier_type;
DROP TYPE IF EXISTS public.enum_canvass_item_suppliers_discount_type;
DROP EXTENSION IF EXISTS timescaledb;
--
-- Name: timescaledb; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS timescaledb WITH SCHEMA public;


--
-- Name: EXTENSION timescaledb; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION timescaledb IS 'Enables scalable inserts and complex queries for time-series data (Community Edition)';


--
-- Name: enum_canvass_item_suppliers_discount_type; Type: TYPE; Schema: public; Owner: prs_user
--

CREATE TYPE public.enum_canvass_item_suppliers_discount_type AS ENUM (
    'percent',
    'fixed'
);


ALTER TYPE public.enum_canvass_item_suppliers_discount_type OWNER TO prs_user;

--
-- Name: enum_canvass_item_suppliers_supplier_type; Type: TYPE; Schema: public; Owner: prs_user
--

CREATE TYPE public.enum_canvass_item_suppliers_supplier_type AS ENUM (
    'supplier',
    'project',
    'company'
);


ALTER TYPE public.enum_canvass_item_suppliers_supplier_type OWNER TO prs_user;

--
-- Name: enum_companies_category; Type: TYPE; Schema: public; Owner: prs_user
--

CREATE TYPE public.enum_companies_category AS ENUM (
    'company',
    'association'
);


ALTER TYPE public.enum_companies_category OWNER TO prs_user;

--
-- Name: enum_non_requisition_items_discount_type; Type: TYPE; Schema: public; Owner: prs_user
--

CREATE TYPE public.enum_non_requisition_items_discount_type AS ENUM (
    'percent',
    'fixed'
);


ALTER TYPE public.enum_non_requisition_items_discount_type OWNER TO prs_user;

--
-- Name: enum_non_requisitions_group_discount_type; Type: TYPE; Schema: public; Owner: prs_user
--

CREATE TYPE public.enum_non_requisitions_group_discount_type AS ENUM (
    'percent',
    'fixed'
);


ALTER TYPE public.enum_non_requisitions_group_discount_type OWNER TO prs_user;

--
-- Name: enum_purchase_order_cancelled_items_supplier_type; Type: TYPE; Schema: public; Owner: prs_user
--

CREATE TYPE public.enum_purchase_order_cancelled_items_supplier_type AS ENUM (
    'supplier',
    'project',
    'company'
);


ALTER TYPE public.enum_purchase_order_cancelled_items_supplier_type OWNER TO prs_user;

--
-- Name: enum_requisitions_category; Type: TYPE; Schema: public; Owner: prs_user
--

CREATE TYPE public.enum_requisitions_category AS ENUM (
    'company',
    'association',
    'project'
);


ALTER TYPE public.enum_requisitions_category OWNER TO prs_user;

--
-- Name: enum_trades_category; Type: TYPE; Schema: public; Owner: prs_user
--

CREATE TYPE public.enum_trades_category AS ENUM (
    'MAJOR',
    'SUB'
);


ALTER TYPE public.enum_trades_category OWNER TO prs_user;

--
-- Name: enum_users_status; Type: TYPE; Schema: public; Owner: prs_user
--

CREATE TYPE public.enum_users_status AS ENUM (
    'active',
    'inactive',
    'on-leave'
);


ALTER TYPE public.enum_users_status OWNER TO prs_user;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: _compressed_hypertable_38; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_38 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_38 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_39; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_39 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_39 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_40; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_40 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_40 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_41; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_41 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_41 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_42; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_42 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_42 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_43; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_43 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_43 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_44; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_44 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_44 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_45; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_45 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_45 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_46; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_46 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_46 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_47; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_47 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_47 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_48; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_48 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_48 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_49; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_49 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_49 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_50; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_50 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_50 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_51; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_51 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_51 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_52; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_52 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_52 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_53; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_53 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_53 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_54; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_54 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_54 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_55; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_55 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_55 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_56; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_56 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_56 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_57; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_57 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_57 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_58; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_58 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_58 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_59; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_59 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_59 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_60; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_60 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_60 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_61; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_61 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_61 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_62; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_62 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_62 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_63; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_63 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_63 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_64; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_64 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_64 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_65; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_65 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_65 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_66; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_66 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_66 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_67; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_67 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_67 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_68; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_68 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_68 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_69; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_69 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_69 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_70; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_70 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_70 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_71; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_71 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_71 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_72; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_72 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_72 OWNER TO prs_user;

--
-- Name: _compressed_hypertable_73; Type: TABLE; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TABLE _timescaledb_internal._compressed_hypertable_73 (
);


ALTER TABLE _timescaledb_internal._compressed_hypertable_73 OWNER TO prs_user;

--
-- Name: SequelizeMeta; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public."SequelizeMeta" (
    name character varying(255) NOT NULL
);


ALTER TABLE public."SequelizeMeta" OWNER TO prs_user;

--
-- Name: approval_types; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.approval_types (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(50) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.approval_types OWNER TO prs_user;

--
-- Name: approval_types_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.approval_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.approval_types_id_seq OWNER TO prs_user;

--
-- Name: approval_types_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.approval_types_id_seq OWNED BY public.approval_types.id;


--
-- Name: association_areas; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.association_areas (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.association_areas OWNER TO prs_user;

--
-- Name: association_areas_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.association_areas_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.association_areas_id_seq OWNER TO prs_user;

--
-- Name: association_areas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.association_areas_id_seq OWNED BY public.association_areas.id;


--
-- Name: attachment_badges; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.attachment_badges (
    id integer NOT NULL,
    user_id integer NOT NULL,
    attachment_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.attachment_badges OWNER TO prs_user;

--
-- Name: attachment_badges_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.attachment_badges_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attachment_badges_id_seq OWNER TO prs_user;

--
-- Name: attachment_badges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.attachment_badges_id_seq OWNED BY public.attachment_badges.id;


--
-- Name: attachments; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.attachments (
    id integer NOT NULL,
    model character varying(100) NOT NULL,
    model_id integer NOT NULL,
    user_id integer NOT NULL,
    file_name text NOT NULL,
    path text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.attachments OWNER TO prs_user;

--
-- Name: attachments_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.attachments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.attachments_id_seq OWNER TO prs_user;

--
-- Name: attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.attachments_id_seq OWNED BY public.attachments.id;


--
-- Name: audit_logs; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.audit_logs (
    id integer NOT NULL,
    action_type character varying(50) NOT NULL,
    module character varying(100) NOT NULL,
    description text NOT NULL,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.audit_logs OWNER TO prs_user;

--
-- Name: COLUMN audit_logs.action_type; Type: COMMENT; Schema: public; Owner: prs_user
--

COMMENT ON COLUMN public.audit_logs.action_type IS 'Type of action performed (update, delete, insert)';


--
-- Name: COLUMN audit_logs.module; Type: COMMENT; Schema: public; Owner: prs_user
--

COMMENT ON COLUMN public.audit_logs.module IS 'System module where the action occurred';


--
-- Name: COLUMN audit_logs.description; Type: COMMENT; Schema: public; Owner: prs_user
--

COMMENT ON COLUMN public.audit_logs.description IS 'Detailed description of the action performed';


--
-- Name: COLUMN audit_logs.metadata; Type: COMMENT; Schema: public; Owner: prs_user
--

COMMENT ON COLUMN public.audit_logs.metadata IS 'Additional contextual data about the action';


--
-- Name: audit_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.audit_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.audit_logs_id_seq OWNER TO prs_user;

--
-- Name: audit_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.audit_logs_id_seq OWNED BY public.audit_logs.id;


--
-- Name: canvass_approvers; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.canvass_approvers (
    id integer NOT NULL,
    canvass_requisition_id integer NOT NULL,
    level integer NOT NULL,
    user_id integer,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    role_id integer NOT NULL,
    is_adhoc boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    alt_approver_id integer,
    reject_reason character varying(255),
    override_by jsonb
);


ALTER TABLE public.canvass_approvers OWNER TO prs_user;

--
-- Name: canvass_approvers_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.canvass_approvers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.canvass_approvers_id_seq OWNER TO prs_user;

--
-- Name: canvass_approvers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.canvass_approvers_id_seq OWNED BY public.canvass_approvers.id;


--
-- Name: canvass_item_suppliers; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.canvass_item_suppliers (
    id integer NOT NULL,
    canvass_item_id integer NOT NULL,
    supplier_id integer,
    term character varying(255) NOT NULL,
    quantity numeric(13,3) NOT NULL,
    "order" integer NOT NULL,
    unit_price double precision NOT NULL,
    discount_type public.enum_canvass_item_suppliers_discount_type DEFAULT 'fixed'::public.enum_canvass_item_suppliers_discount_type NOT NULL,
    is_selected boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    supplier_type public.enum_canvass_item_suppliers_supplier_type DEFAULT 'supplier'::public.enum_canvass_item_suppliers_supplier_type NOT NULL,
    discount_value double precision DEFAULT '0'::double precision NOT NULL,
    supplier_name character varying(255),
    supplier_name_locked boolean DEFAULT false NOT NULL
);


ALTER TABLE public.canvass_item_suppliers OWNER TO prs_user;

--
-- Name: canvass_item_suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.canvass_item_suppliers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.canvass_item_suppliers_id_seq OWNER TO prs_user;

--
-- Name: canvass_item_suppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.canvass_item_suppliers_id_seq OWNED BY public.canvass_item_suppliers.id;


--
-- Name: canvass_items; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.canvass_items (
    id integer NOT NULL,
    canvass_requisition_id integer NOT NULL,
    requisition_item_list_id integer NOT NULL,
    status character varying(255) DEFAULT 'new'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    requisition_id integer,
    cancelled_qty numeric(13,3) DEFAULT 0 NOT NULL
);


ALTER TABLE public.canvass_items OWNER TO prs_user;

--
-- Name: canvass_items_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.canvass_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.canvass_items_id_seq OWNER TO prs_user;

--
-- Name: canvass_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.canvass_items_id_seq OWNED BY public.canvass_items.id;


--
-- Name: canvass_requisitions; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.canvass_requisitions (
    id integer NOT NULL,
    requisition_id integer NOT NULL,
    cs_number character varying(8),
    cs_letter character varying(2) NOT NULL,
    draft_cs_number character varying(8),
    status character varying(255) DEFAULT 'draft'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    cancelled_at timestamp with time zone,
    cancelled_by integer,
    cancellation_reason character varying(100)
);


ALTER TABLE public.canvass_requisitions OWNER TO prs_user;

--
-- Name: canvass_requisitions_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.canvass_requisitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.canvass_requisitions_id_seq OWNER TO prs_user;

--
-- Name: canvass_requisitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.canvass_requisitions_id_seq OWNED BY public.canvass_requisitions.id;


--
-- Name: comment_badges; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.comment_badges (
    id integer NOT NULL,
    user_id integer NOT NULL,
    comment_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.comment_badges OWNER TO prs_user;

--
-- Name: comment_badges_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.comment_badges_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comment_badges_id_seq OWNER TO prs_user;

--
-- Name: comment_badges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.comment_badges_id_seq OWNED BY public.comment_badges.id;


--
-- Name: comments; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.comments (
    id integer NOT NULL,
    model character varying(100) NOT NULL,
    model_id integer NOT NULL,
    commented_by integer NOT NULL,
    comment text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.comments OWNER TO prs_user;

--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comments_id_seq OWNER TO prs_user;

--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: companies; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.companies (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    initial character varying(255) NOT NULL,
    tin character varying(255) NOT NULL,
    address character varying(255),
    contact_number character varying(255),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    code bigint NOT NULL,
    category public.enum_companies_category DEFAULT 'company'::public.enum_companies_category NOT NULL,
    area_code character varying(255)
);


ALTER TABLE public.companies OWNER TO prs_user;

--
-- Name: companies_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.companies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.companies_id_seq OWNER TO prs_user;

--
-- Name: companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.companies_id_seq OWNED BY public.companies.id;


--
-- Name: delivery_receipt_invoices; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.delivery_receipt_invoices (
    id integer NOT NULL,
    delivery_receipt_id integer NOT NULL,
    invoice_no character varying(255),
    issued_invoice_date timestamp with time zone,
    total_sales numeric(20,2),
    vat_amount numeric(20,2),
    vat_exempted_amount numeric(20,2),
    zero_rated_amount numeric(20,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.delivery_receipt_invoices OWNER TO prs_user;

--
-- Name: delivery_receipt_invoices_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.delivery_receipt_invoices_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_receipt_invoices_id_seq OWNER TO prs_user;

--
-- Name: delivery_receipt_invoices_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.delivery_receipt_invoices_id_seq OWNED BY public.delivery_receipt_invoices.id;


--
-- Name: delivery_receipt_items; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.delivery_receipt_items (
    id integer NOT NULL,
    dr_id integer NOT NULL,
    po_id integer NOT NULL,
    item_id integer NOT NULL,
    item_des character varying(255) NOT NULL,
    qty_ordered numeric(13,3) NOT NULL,
    qty_delivered numeric(13,3),
    unit character varying(10) NOT NULL,
    date_delivered timestamp with time zone,
    delivery_status character varying(50),
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    qty_returned numeric(13,3),
    has_returns boolean DEFAULT false,
    po_item_id integer,
    item_type character varying(255)
);


ALTER TABLE public.delivery_receipt_items OWNER TO prs_user;

--
-- Name: delivery_receipt_items_history; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.delivery_receipt_items_history (
    id integer NOT NULL,
    delivery_receipt_item_id integer NOT NULL,
    qty_ordered numeric(10,3) NOT NULL,
    qty_delivered numeric(10,3) NOT NULL,
    date_delivered timestamp with time zone,
    status character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    qty_returned numeric(10,3) NOT NULL
);


ALTER TABLE public.delivery_receipt_items_history OWNER TO prs_user;

--
-- Name: delivery_receipt_items_history_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.delivery_receipt_items_history_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_receipt_items_history_id_seq OWNER TO prs_user;

--
-- Name: delivery_receipt_items_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.delivery_receipt_items_history_id_seq OWNED BY public.delivery_receipt_items_history.id;


--
-- Name: delivery_receipt_items_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.delivery_receipt_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_receipt_items_id_seq OWNER TO prs_user;

--
-- Name: delivery_receipt_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.delivery_receipt_items_id_seq OWNED BY public.delivery_receipt_items.id;


--
-- Name: delivery_receipts; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.delivery_receipts (
    id integer NOT NULL,
    requisition_id integer,
    company_code character varying(255) NOT NULL,
    dr_number character varying(255),
    supplier character varying(255),
    is_draft boolean DEFAULT true NOT NULL,
    draft_dr_number character varying(255),
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    po_id integer,
    latest_delivery_date timestamp with time zone,
    latest_delivery_status character varying(255),
    supplier_name_locked boolean DEFAULT false NOT NULL,
    invoice_id integer,
    invoice_number character varying(255),
    supplier_delivery_issued_date timestamp with time zone,
    issued_date timestamp with time zone,
    status character varying(255),
    cancelled_at timestamp with time zone,
    cancelled_by integer,
    cancellation_reason character varying(100)
);


ALTER TABLE public.delivery_receipts OWNER TO prs_user;

--
-- Name: delivery_receipts_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.delivery_receipts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.delivery_receipts_id_seq OWNER TO prs_user;

--
-- Name: delivery_receipts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.delivery_receipts_id_seq OWNED BY public.delivery_receipts.id;


--
-- Name: department_approvals; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.department_approvals (
    id integer NOT NULL,
    department_id integer NOT NULL,
    approval_type_code character varying(50) NOT NULL,
    level integer NOT NULL,
    is_optional boolean DEFAULT false NOT NULL,
    approver_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.department_approvals OWNER TO prs_user;

--
-- Name: department_approvals_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.department_approvals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.department_approvals_id_seq OWNER TO prs_user;

--
-- Name: department_approvals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.department_approvals_id_seq OWNED BY public.department_approvals.id;


--
-- Name: department_association_approvals; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.department_association_approvals (
    id integer NOT NULL,
    approval_type_code character varying(50) NOT NULL,
    level integer NOT NULL,
    area_code character varying(100),
    approver_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL
);


ALTER TABLE public.department_association_approvals OWNER TO prs_user;

--
-- Name: COLUMN department_association_approvals.area_code; Type: COMMENT; Schema: public; Owner: prs_user
--

COMMENT ON COLUMN public.department_association_approvals.area_code IS 'Area code for level 1 approvers only';


--
-- Name: department_association_approvals_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.department_association_approvals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.department_association_approvals_id_seq OWNER TO prs_user;

--
-- Name: department_association_approvals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.department_association_approvals_id_seq OWNED BY public.department_association_approvals.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.departments (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    code integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.departments OWNER TO prs_user;

--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.departments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.departments_id_seq OWNER TO prs_user;

--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.departments_id_seq OWNED BY public.departments.id;


--
-- Name: force_close_logs; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.force_close_logs (
    id integer NOT NULL,
    requisition_id integer NOT NULL,
    user_id integer NOT NULL,
    scenario_type character varying(50) NOT NULL,
    validation_path character varying(50) NOT NULL,
    quantities_affected json,
    documents_cancelled json,
    po_adjustments json,
    force_close_notes text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.force_close_logs OWNER TO prs_user;

--
-- Name: force_close_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.force_close_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.force_close_logs_id_seq OWNER TO prs_user;

--
-- Name: force_close_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.force_close_logs_id_seq OWNED BY public.force_close_logs.id;


--
-- Name: gate_passes; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.gate_passes (
    id integer NOT NULL,
    requisition_id integer NOT NULL,
    purchase_order_id integer NOT NULL,
    gate_pass_number integer NOT NULL,
    "createdAt" timestamp with time zone NOT NULL,
    "updatedAt" timestamp with time zone NOT NULL
);


ALTER TABLE public.gate_passes OWNER TO prs_user;

--
-- Name: gate_passes_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.gate_passes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.gate_passes_id_seq OWNER TO prs_user;

--
-- Name: gate_passes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.gate_passes_id_seq OWNED BY public.gate_passes.id;


--
-- Name: histories; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.histories (
    id integer NOT NULL,
    rs_number character varying(20) NOT NULL,
    item_id integer NOT NULL,
    date_requested timestamp with time zone NOT NULL,
    quantity_requested numeric(13,3),
    price character varying(255),
    quantity_delivered numeric(13,3),
    date_delivered timestamp with time zone,
    type character varying(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    company_id integer,
    project_id integer,
    department_id integer,
    rs_letter character varying(2) DEFAULT 'AA'::character varying NOT NULL,
    dr_item_id integer
);


ALTER TABLE public.histories OWNER TO prs_user;

--
-- Name: histories_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.histories_id_seq OWNER TO prs_user;

--
-- Name: histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.histories_id_seq OWNED BY public.histories.id;


--
-- Name: invoice_report_histories; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.invoice_report_histories (
    id integer NOT NULL,
    requisition_id integer NOT NULL,
    purchase_order_id integer NOT NULL,
    invoice_report_id integer NOT NULL,
    ir_number character varying(255) NOT NULL,
    supplier_invoice_no character varying(255) NOT NULL,
    issued_invoice_date timestamp with time zone NOT NULL,
    invoice_amount numeric(10,2) NOT NULL,
    status character varying(50) DEFAULT '--'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.invoice_report_histories OWNER TO prs_user;

--
-- Name: invoice_report_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.invoice_report_histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.invoice_report_histories_id_seq OWNER TO prs_user;

--
-- Name: invoice_report_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.invoice_report_histories_id_seq OWNED BY public.invoice_report_histories.id;


--
-- Name: invoice_reports; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.invoice_reports (
    id integer NOT NULL,
    ir_number character varying(255),
    ir_draft_number character varying(255),
    is_draft boolean DEFAULT false NOT NULL,
    requisition_id integer NOT NULL,
    purchase_order_id integer NOT NULL,
    company_code character varying(255) NOT NULL,
    supplier_invoice_no character varying(255),
    issued_invoice_date timestamp with time zone,
    invoice_amount numeric(10,2),
    note character varying(255),
    created_by integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    status character varying(50) DEFAULT '--'::character varying NOT NULL,
    payment_request_id integer,
    cancelled_at timestamp with time zone,
    cancelled_by integer,
    cancellation_reason character varying(100)
);


ALTER TABLE public.invoice_reports OWNER TO prs_user;

--
-- Name: invoice_reports_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.invoice_reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.invoice_reports_id_seq OWNER TO prs_user;

--
-- Name: invoice_reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.invoice_reports_id_seq OWNED BY public.invoice_reports.id;


--
-- Name: items; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.items (
    id integer NOT NULL,
    item_cd character varying(20),
    itm_des character varying(255) NOT NULL,
    unit character varying(20),
    acct_cd character varying(20),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    gfq numeric(13,3),
    trade_code integer,
    remaining_gfq numeric(13,3),
    is_steelbars boolean DEFAULT false NOT NULL
);


ALTER TABLE public.items OWNER TO prs_user;

--
-- Name: items_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.items_id_seq OWNER TO prs_user;

--
-- Name: items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.items_id_seq OWNED BY public.items.id;


--
-- Name: leaves; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.leaves (
    id integer NOT NULL,
    user_id integer NOT NULL,
    start_date timestamp with time zone NOT NULL,
    end_date timestamp with time zone NOT NULL,
    total_days integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.leaves OWNER TO prs_user;

--
-- Name: leaves_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.leaves_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.leaves_id_seq OWNER TO prs_user;

--
-- Name: leaves_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.leaves_id_seq OWNED BY public.leaves.id;


--
-- Name: non_ofm_items; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.non_ofm_items (
    id integer NOT NULL,
    item_name character varying(255) NOT NULL,
    item_type character varying(20),
    unit character varying(20),
    acct_cd character varying(20),
    notes character varying(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.non_ofm_items OWNER TO prs_user;

--
-- Name: non_ofm_items_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.non_ofm_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.non_ofm_items_id_seq OWNER TO prs_user;

--
-- Name: non_ofm_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.non_ofm_items_id_seq OWNED BY public.non_ofm_items.id;


--
-- Name: non_requisition_approvers; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.non_requisition_approvers (
    id integer NOT NULL,
    non_requisition_id integer NOT NULL,
    level integer NOT NULL,
    user_id integer,
    alt_approver_id integer,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    role_id integer NOT NULL,
    is_adhoc boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    override_by jsonb
);


ALTER TABLE public.non_requisition_approvers OWNER TO prs_user;

--
-- Name: non_requisition_approvers_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.non_requisition_approvers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.non_requisition_approvers_id_seq OWNER TO prs_user;

--
-- Name: non_requisition_approvers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.non_requisition_approvers_id_seq OWNED BY public.non_requisition_approvers.id;


--
-- Name: non_requisition_histories; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.non_requisition_histories (
    id integer NOT NULL,
    non_requisition_id integer NOT NULL,
    approver_id integer NOT NULL,
    status character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.non_requisition_histories OWNER TO prs_user;

--
-- Name: non_requisition_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.non_requisition_histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.non_requisition_histories_id_seq OWNER TO prs_user;

--
-- Name: non_requisition_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.non_requisition_histories_id_seq OWNED BY public.non_requisition_histories.id;


--
-- Name: non_requisition_items; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.non_requisition_items (
    id integer NOT NULL,
    non_requisition_id integer NOT NULL,
    name character varying(255) NOT NULL,
    quantity numeric(13,3) NOT NULL,
    amount double precision,
    discount_value double precision NOT NULL,
    discount_type public.enum_non_requisition_items_discount_type DEFAULT 'fixed'::public.enum_non_requisition_items_discount_type NOT NULL,
    discounted_price double precision NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    unit character varying(255) DEFAULT 'm'::character varying NOT NULL
);


ALTER TABLE public.non_requisition_items OWNER TO prs_user;

--
-- Name: non_requisition_items_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.non_requisition_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.non_requisition_items_id_seq OWNER TO prs_user;

--
-- Name: non_requisition_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.non_requisition_items_id_seq OWNED BY public.non_requisition_items.id;


--
-- Name: non_requisitions; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.non_requisitions (
    id integer NOT NULL,
    non_rs_letter character varying(2) NOT NULL,
    non_rs_number character varying(8),
    draft_non_rs_number character varying(8),
    charge_to character varying(255),
    charge_to_id integer,
    created_by integer NOT NULL,
    invoice_date timestamp with time zone NOT NULL,
    status character varying(50) DEFAULT 'draft'::character varying NOT NULL,
    invoice_no character varying(255) NOT NULL,
    payable_to character varying(255) NOT NULL,
    total_amount numeric(20,2),
    total_discount numeric(20,2),
    total_discounted_amount numeric(20,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    company_id integer DEFAULT 1 NOT NULL,
    project_id integer,
    department_id integer DEFAULT 1 NOT NULL,
    supplier_id integer DEFAULT 1 NOT NULL,
    category character varying(255) DEFAULT 'company'::character varying NOT NULL,
    group_discount_type public.enum_non_requisitions_group_discount_type,
    group_discount_price double precision,
    supplier_invoice_amount double precision DEFAULT '0'::double precision NOT NULL
);


ALTER TABLE public.non_requisitions OWNER TO prs_user;

--
-- Name: non_requisitions_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.non_requisitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.non_requisitions_id_seq OWNER TO prs_user;

--
-- Name: non_requisitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.non_requisitions_id_seq OWNED BY public.non_requisitions.id;


--
-- Name: note_badges; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.note_badges (
    id integer NOT NULL,
    user_id integer NOT NULL,
    note_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.note_badges OWNER TO prs_user;

--
-- Name: note_badges_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.note_badges_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.note_badges_id_seq OWNER TO prs_user;

--
-- Name: note_badges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.note_badges_id_seq OWNED BY public.note_badges.id;


--
-- Name: notes; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.notes (
    id integer NOT NULL,
    model character varying(100) NOT NULL,
    model_id integer NOT NULL,
    user_name character varying(255) NOT NULL,
    user_type character varying(255),
    comment_type character varying(255),
    note text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.notes OWNER TO prs_user;

--
-- Name: notes_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.notes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notes_id_seq OWNER TO prs_user;

--
-- Name: notes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.notes_id_seq OWNED BY public.notes.id;


--
-- Name: notifications; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.notifications (
    id integer NOT NULL,
    title character varying(100) NOT NULL,
    message text NOT NULL,
    type character varying(50) NOT NULL,
    recipient_role_id integer,
    recipient_user_ids integer[] DEFAULT ARRAY[]::integer[],
    sender_id integer NOT NULL,
    viewed_by integer[] DEFAULT ARRAY[]::integer[] NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    meta_data json
);


ALTER TABLE public.notifications OWNER TO prs_user;

--
-- Name: notifications_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.notifications_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.notifications_id_seq OWNER TO prs_user;

--
-- Name: notifications_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.notifications_id_seq OWNED BY public.notifications.id;


--
-- Name: ofm_item_lists; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.ofm_item_lists (
    id integer NOT NULL,
    list_name character varying(100),
    company_code integer,
    department_code integer,
    project_code character varying(20),
    trade_code integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.ofm_item_lists OWNER TO prs_user;

--
-- Name: ofm_item_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.ofm_item_lists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ofm_item_lists_id_seq OWNER TO prs_user;

--
-- Name: ofm_item_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.ofm_item_lists_id_seq OWNED BY public.ofm_item_lists.id;


--
-- Name: ofm_list_items; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.ofm_list_items (
    id integer NOT NULL,
    ofm_list_id integer,
    ofm_item_id integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.ofm_list_items OWNER TO prs_user;

--
-- Name: ofm_list_items_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.ofm_list_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.ofm_list_items_id_seq OWNER TO prs_user;

--
-- Name: ofm_list_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.ofm_list_items_id_seq OWNED BY public.ofm_list_items.id;


--
-- Name: permissions; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.permissions (
    id integer NOT NULL,
    module character varying(50) NOT NULL,
    action character varying(50) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.permissions OWNER TO prs_user;

--
-- Name: permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.permissions_id_seq OWNER TO prs_user;

--
-- Name: permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.permissions_id_seq OWNED BY public.permissions.id;


--
-- Name: project_approvals; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.project_approvals (
    id integer NOT NULL,
    project_id integer NOT NULL,
    approval_type_code character varying(50) NOT NULL,
    level integer NOT NULL,
    is_optional boolean DEFAULT false NOT NULL,
    approver_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.project_approvals OWNER TO prs_user;

--
-- Name: project_approvals_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.project_approvals_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_approvals_id_seq OWNER TO prs_user;

--
-- Name: project_approvals_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.project_approvals_id_seq OWNED BY public.project_approvals.id;


--
-- Name: project_companies; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.project_companies (
    id integer NOT NULL,
    project_id integer NOT NULL,
    company_id integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.project_companies OWNER TO prs_user;

--
-- Name: project_companies_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.project_companies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.project_companies_id_seq OWNER TO prs_user;

--
-- Name: project_companies_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.project_companies_id_seq OWNED BY public.project_companies.id;


--
-- Name: projects; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.projects (
    id integer NOT NULL,
    code character varying(255) NOT NULL,
    name character varying(255) NOT NULL,
    initial character varying(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    company_code integer,
    address character varying(255),
    company_id integer
);


ALTER TABLE public.projects OWNER TO prs_user;

--
-- Name: projects_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.projects_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projects_id_seq OWNER TO prs_user;

--
-- Name: projects_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.projects_id_seq OWNED BY public.projects.id;


--
-- Name: projects_trades; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.projects_trades (
    id integer NOT NULL,
    project_id integer NOT NULL,
    trade_id integer NOT NULL,
    engineer_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.projects_trades OWNER TO prs_user;

--
-- Name: projects_trades_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.projects_trades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.projects_trades_id_seq OWNER TO prs_user;

--
-- Name: projects_trades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.projects_trades_id_seq OWNED BY public.projects_trades.id;


--
-- Name: prs_timescaledb_status; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.prs_timescaledb_status (
    id integer NOT NULL,
    table_name character varying(255) NOT NULL,
    is_hypertable boolean DEFAULT false,
    chunk_time_interval character varying(50),
    compression_enabled boolean DEFAULT false,
    total_chunks integer DEFAULT 0,
    table_size_pretty character varying(50),
    notes text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.prs_timescaledb_status OWNER TO prs_user;

--
-- Name: prs_timescaledb_status_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.prs_timescaledb_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.prs_timescaledb_status_id_seq OWNER TO prs_user;

--
-- Name: prs_timescaledb_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.prs_timescaledb_status_id_seq OWNED BY public.prs_timescaledb_status.id;


--
-- Name: purchase_order_approvers; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.purchase_order_approvers (
    id integer NOT NULL,
    purchase_order_id integer NOT NULL,
    level integer NOT NULL,
    user_id integer,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    role_id integer NOT NULL,
    is_adhoc boolean DEFAULT false NOT NULL,
    alt_approver_id integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    override_by jsonb,
    added_by integer
);


ALTER TABLE public.purchase_order_approvers OWNER TO prs_user;

--
-- Name: purchase_order_approvers_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.purchase_order_approvers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.purchase_order_approvers_id_seq OWNER TO prs_user;

--
-- Name: purchase_order_approvers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.purchase_order_approvers_id_seq OWNED BY public.purchase_order_approvers.id;


--
-- Name: purchase_order_cancelled_items; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.purchase_order_cancelled_items (
    id integer NOT NULL,
    purchase_order_id integer NOT NULL,
    requisition_id integer NOT NULL,
    canvass_requisition_id integer NOT NULL,
    canvass_item_id integer NOT NULL,
    requisition_item_list_id integer NOT NULL,
    supplier_id integer,
    supplier_type public.enum_purchase_order_cancelled_items_supplier_type DEFAULT 'supplier'::public.enum_purchase_order_cancelled_items_supplier_type NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    status character varying(255) DEFAULT 'new'::character varying NOT NULL
);


ALTER TABLE public.purchase_order_cancelled_items OWNER TO prs_user;

--
-- Name: purchase_order_cancelled_items_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.purchase_order_cancelled_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.purchase_order_cancelled_items_id_seq OWNER TO prs_user;

--
-- Name: purchase_order_cancelled_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.purchase_order_cancelled_items_id_seq OWNED BY public.purchase_order_cancelled_items.id;


--
-- Name: purchase_order_items; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.purchase_order_items (
    id integer NOT NULL,
    purchase_order_id integer NOT NULL,
    canvass_item_id integer NOT NULL,
    requisition_item_list_id integer NOT NULL,
    quantity_purchased numeric(13,3) DEFAULT 0 NOT NULL,
    canvass_item_supplier_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.purchase_order_items OWNER TO prs_user;

--
-- Name: purchase_order_items_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.purchase_order_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.purchase_order_items_id_seq OWNER TO prs_user;

--
-- Name: purchase_order_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.purchase_order_items_id_seq OWNED BY public.purchase_order_items.id;


--
-- Name: purchase_orders; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.purchase_orders (
    id integer NOT NULL,
    po_number character varying(255) NOT NULL,
    po_letter character varying(255) NOT NULL,
    requisition_id integer NOT NULL,
    canvass_requisition_id integer NOT NULL,
    supplier_id integer NOT NULL,
    supplier_type character varying(50) NOT NULL,
    status character varying(50) DEFAULT 'for_po_review'::character varying NOT NULL,
    delivery_address text,
    terms text,
    warranty_id integer,
    deposit_percent numeric(20,2),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    total_amount numeric(20,2),
    total_discount numeric(20,2),
    total_discounted_amount numeric(20,2),
    supplier_name character varying(255),
    supplier_name_locked boolean DEFAULT false NOT NULL,
    assigned_to integer,
    new_delivery_address text,
    is_new_delivery_address boolean DEFAULT false NOT NULL,
    added_discount numeric(20,2) DEFAULT 0,
    is_added_discount_fixed_amount boolean DEFAULT false NOT NULL,
    is_added_discount_percentage boolean DEFAULT false NOT NULL,
    was_cancelled boolean DEFAULT false NOT NULL,
    system_generated_notes text,
    original_amount numeric(15,2),
    original_quantity integer,
    withholding_tax_deduction numeric,
    delivery_fee numeric,
    tip numeric,
    extra_charges numeric
);


ALTER TABLE public.purchase_orders OWNER TO prs_user;

--
-- Name: purchase_orders_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.purchase_orders_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.purchase_orders_id_seq OWNER TO prs_user;

--
-- Name: purchase_orders_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.purchase_orders_id_seq OWNED BY public.purchase_orders.id;


--
-- Name: requisition_approvers; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.requisition_approvers (
    id integer NOT NULL,
    requisition_id integer NOT NULL,
    model_id integer NOT NULL,
    approver_id integer,
    level integer NOT NULL,
    is_alt_approver boolean NOT NULL,
    model_type character varying(255) NOT NULL,
    status character varying(255) NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    alt_approver_id integer,
    is_optional_approver boolean DEFAULT false,
    added_by integer,
    optional_approver_item_ids integer[],
    is_additional_approver boolean DEFAULT false NOT NULL,
    override_by jsonb,
    approver_level integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.requisition_approvers OWNER TO prs_user;

--
-- Name: requisition_approvers_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.requisition_approvers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requisition_approvers_id_seq OWNER TO prs_user;

--
-- Name: requisition_approvers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.requisition_approvers_id_seq OWNED BY public.requisition_approvers.id;


--
-- Name: requisition_badges; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.requisition_badges (
    id integer NOT NULL,
    requisition_id integer NOT NULL,
    created_by integer NOT NULL,
    seen_by integer[] DEFAULT ARRAY[]::integer[],
    model character varying(255) NOT NULL,
    model_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.requisition_badges OWNER TO prs_user;

--
-- Name: requisition_badges_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.requisition_badges_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requisition_badges_id_seq OWNER TO prs_user;

--
-- Name: requisition_badges_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.requisition_badges_id_seq OWNED BY public.requisition_badges.id;


--
-- Name: requisition_canvass_histories; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.requisition_canvass_histories (
    id integer NOT NULL,
    requisition_id integer NOT NULL,
    canvass_number character varying(255) NOT NULL,
    supplier character varying(255) NOT NULL,
    item character varying(255) NOT NULL,
    price double precision NOT NULL,
    discount double precision NOT NULL,
    canvass_date timestamp with time zone NOT NULL,
    status character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    requisition_item_list_id integer,
    supplier_id integer,
    canvass_requisition_id integer
);


ALTER TABLE public.requisition_canvass_histories OWNER TO prs_user;

--
-- Name: requisition_canvass_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.requisition_canvass_histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requisition_canvass_histories_id_seq OWNER TO prs_user;

--
-- Name: requisition_canvass_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.requisition_canvass_histories_id_seq OWNED BY public.requisition_canvass_histories.id;


--
-- Name: requisition_delivery_histories; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.requisition_delivery_histories (
    id integer NOT NULL,
    requisition_id integer NOT NULL,
    dr_number character varying(255) NOT NULL,
    supplier character varying(255) NOT NULL,
    date_ordered timestamp with time zone NOT NULL,
    quantity_ordered numeric(13,3) NOT NULL,
    quantity_delivered numeric(13,3) NOT NULL,
    date_delivered timestamp with time zone NOT NULL,
    status character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.requisition_delivery_histories OWNER TO prs_user;

--
-- Name: requisition_delivery_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.requisition_delivery_histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requisition_delivery_histories_id_seq OWNER TO prs_user;

--
-- Name: requisition_delivery_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.requisition_delivery_histories_id_seq OWNED BY public.requisition_delivery_histories.id;


--
-- Name: requisition_item_histories; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.requisition_item_histories (
    id integer NOT NULL,
    requisition_id integer NOT NULL,
    item character varying(255) NOT NULL,
    quantity_requested double precision NOT NULL,
    quantity_ordered double precision NOT NULL,
    quantity_delivered double precision NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.requisition_item_histories OWNER TO prs_user;

--
-- Name: requisition_item_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.requisition_item_histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requisition_item_histories_id_seq OWNER TO prs_user;

--
-- Name: requisition_item_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.requisition_item_histories_id_seq OWNED BY public.requisition_item_histories.id;


--
-- Name: requisition_item_lists; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.requisition_item_lists (
    id integer NOT NULL,
    requisition_id integer NOT NULL,
    item_id integer,
    quantity numeric(13,3) NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    item_type text,
    account_code character varying(255),
    ofm_list_id integer
);


ALTER TABLE public.requisition_item_lists OWNER TO prs_user;

--
-- Name: requisition_item_lists_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.requisition_item_lists_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requisition_item_lists_id_seq OWNER TO prs_user;

--
-- Name: requisition_item_lists_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.requisition_item_lists_id_seq OWNED BY public.requisition_item_lists.id;


--
-- Name: requisition_order_histories; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.requisition_order_histories (
    id integer NOT NULL,
    requisition_id integer NOT NULL,
    po_number character varying(255) NOT NULL,
    supplier character varying(255) NOT NULL,
    po_price double precision NOT NULL,
    date_ordered timestamp with time zone NOT NULL,
    status character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.requisition_order_histories OWNER TO prs_user;

--
-- Name: requisition_order_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.requisition_order_histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requisition_order_histories_id_seq OWNER TO prs_user;

--
-- Name: requisition_order_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.requisition_order_histories_id_seq OWNED BY public.requisition_order_histories.id;


--
-- Name: requisition_payment_histories; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.requisition_payment_histories (
    id integer NOT NULL,
    requisition_id integer NOT NULL,
    pr_number character varying(255) NOT NULL,
    amount double precision NOT NULL,
    supplier character varying(255) NOT NULL,
    status character varying(255) NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.requisition_payment_histories OWNER TO prs_user;

--
-- Name: requisition_payment_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.requisition_payment_histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requisition_payment_histories_id_seq OWNER TO prs_user;

--
-- Name: requisition_payment_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.requisition_payment_histories_id_seq OWNED BY public.requisition_payment_histories.id;


--
-- Name: requisition_return_histories; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.requisition_return_histories (
    id integer NOT NULL,
    requisition_id integer NOT NULL,
    dr_number character varying(255) NOT NULL,
    item character varying(255) NOT NULL,
    supplier character varying(255) NOT NULL,
    status character varying(255) NOT NULL,
    quantity_ordered numeric(13,3) NOT NULL,
    quantity_returned numeric(13,3) NOT NULL,
    return_date timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.requisition_return_histories OWNER TO prs_user;

--
-- Name: requisition_return_histories_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.requisition_return_histories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requisition_return_histories_id_seq OWNER TO prs_user;

--
-- Name: requisition_return_histories_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.requisition_return_histories_id_seq OWNED BY public.requisition_return_histories.id;


--
-- Name: requisitions; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.requisitions (
    id integer NOT NULL,
    rs_number character varying(255),
    company_code character varying(5) NOT NULL,
    rs_letter character varying(2) NOT NULL,
    created_by integer NOT NULL,
    company_id integer NOT NULL,
    department_id integer NOT NULL,
    project_id integer,
    date_required timestamp with time zone NOT NULL,
    delivery_address character varying(255) NOT NULL,
    purpose character varying(255),
    charge_to character varying(255),
    status character varying(20) NOT NULL,
    assigned_to integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    type character varying(255) DEFAULT 'ofm'::character varying NOT NULL,
    draft_rs_number character varying(255),
    charge_to_id integer,
    company_name character varying(255),
    company_name_locked boolean DEFAULT false NOT NULL,
    category public.enum_requisitions_category DEFAULT 'company'::public.enum_requisitions_category NOT NULL,
    "chargeToId" integer,
    force_closed_at timestamp with time zone,
    force_closed_by integer,
    force_close_reason text,
    force_close_scenario character varying(50)
);


ALTER TABLE public.requisitions OWNER TO prs_user;

--
-- Name: requisitions_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.requisitions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.requisitions_id_seq OWNER TO prs_user;

--
-- Name: requisitions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.requisitions_id_seq OWNED BY public.requisitions.id;


--
-- Name: role_permissions; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.role_permissions (
    id integer NOT NULL,
    role_id integer NOT NULL,
    permission_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.role_permissions OWNER TO prs_user;

--
-- Name: role_permissions_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.role_permissions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.role_permissions_id_seq OWNER TO prs_user;

--
-- Name: role_permissions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.role_permissions_id_seq OWNED BY public.role_permissions.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    is_permanent boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.roles OWNER TO prs_user;

--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.roles_id_seq OWNER TO prs_user;

--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: rs_payment_request_approvers; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.rs_payment_request_approvers (
    id integer NOT NULL,
    payment_request_id integer NOT NULL,
    level integer NOT NULL,
    user_id integer,
    alt_approver_id integer,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    role_id integer NOT NULL,
    is_adhoc boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    override_by jsonb
);


ALTER TABLE public.rs_payment_request_approvers OWNER TO prs_user;

--
-- Name: rs_payment_request_approvers_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.rs_payment_request_approvers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rs_payment_request_approvers_id_seq OWNER TO prs_user;

--
-- Name: rs_payment_request_approvers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.rs_payment_request_approvers_id_seq OWNED BY public.rs_payment_request_approvers.id;


--
-- Name: rs_payment_requests; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.rs_payment_requests (
    id integer NOT NULL,
    draft_pr_number character varying(8),
    pr_number character varying(8),
    pr_letter character varying(2) NOT NULL,
    is_draft boolean DEFAULT false NOT NULL,
    requisition_id integer NOT NULL,
    purchase_order_id integer NOT NULL,
    delivery_invoice_id integer,
    terms_data jsonb,
    payable_date timestamp with time zone,
    discount_in character varying(255),
    discount_percentage numeric,
    discount_amount numeric,
    withholding_tax_deduction numeric,
    delivery_fee numeric,
    tip numeric,
    extra_charges numeric,
    status character varying(255) NOT NULL,
    total_amount numeric,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    last_approver_id integer,
    cancelled_at timestamp with time zone,
    cancelled_by integer,
    cancellation_reason character varying(100)
);


ALTER TABLE public.rs_payment_requests OWNER TO prs_user;

--
-- Name: rs_payment_requests_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.rs_payment_requests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.rs_payment_requests_id_seq OWNER TO prs_user;

--
-- Name: rs_payment_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.rs_payment_requests_id_seq OWNED BY public.rs_payment_requests.id;


--
-- Name: steelbars; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.steelbars (
    id integer NOT NULL,
    grade character varying(20) NOT NULL,
    diameter numeric NOT NULL,
    length numeric NOT NULL,
    weight numeric NOT NULL,
    kg_per_meter numeric NOT NULL,
    ofm_acctcd character varying(50),
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.steelbars OWNER TO prs_user;

--
-- Name: steelbars_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.steelbars_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.steelbars_id_seq OWNER TO prs_user;

--
-- Name: steelbars_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.steelbars_id_seq OWNED BY public.steelbars.id;


--
-- Name: suppliers; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.suppliers (
    id integer NOT NULL,
    user_id integer NOT NULL,
    name character varying(100) NOT NULL,
    contact character varying(20),
    tin character varying(20) NOT NULL,
    address text NOT NULL,
    contact_person character varying(100),
    contact_number character varying(50),
    citizenship_code character varying(2) NOT NULL,
    nature_of_income character varying(20) NOT NULL,
    pay_code character varying(4) NOT NULL,
    ic_code character varying(2) NOT NULL,
    status character varying(255),
    deleted_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    line_of_business character varying(50)
);


ALTER TABLE public.suppliers OWNER TO prs_user;

--
-- Name: suppliers_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.suppliers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.suppliers_id_seq OWNER TO prs_user;

--
-- Name: suppliers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.suppliers_id_seq OWNED BY public.suppliers.id;


--
-- Name: syncs; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.syncs (
    id integer NOT NULL,
    model character varying(50) NOT NULL,
    last_synced_at timestamp with time zone NOT NULL
);


ALTER TABLE public.syncs OWNER TO prs_user;

--
-- Name: syncs_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.syncs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.syncs_id_seq OWNER TO prs_user;

--
-- Name: syncs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.syncs_id_seq OWNED BY public.syncs.id;


--
-- Name: timescaledb_migration_status; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.timescaledb_migration_status (
    id integer NOT NULL,
    table_name character varying(255) NOT NULL,
    is_hypertable_ready boolean DEFAULT false,
    constraint_migration_needed boolean DEFAULT true,
    compression_enabled boolean DEFAULT false,
    chunk_time_interval character varying(50),
    compression_after character varying(50),
    notes text,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.timescaledb_migration_status OWNER TO prs_user;

--
-- Name: timescaledb_migration_status_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.timescaledb_migration_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.timescaledb_migration_status_id_seq OWNER TO prs_user;

--
-- Name: timescaledb_migration_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.timescaledb_migration_status_id_seq OWNED BY public.timescaledb_migration_status.id;


--
-- Name: tom_items; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.tom_items (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    unit character varying(255) NOT NULL,
    quantity numeric(13,3) NOT NULL,
    comment text,
    requisition_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    notes text
);


ALTER TABLE public.tom_items OWNER TO prs_user;

--
-- Name: tom_items_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.tom_items_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tom_items_id_seq OWNER TO prs_user;

--
-- Name: tom_items_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.tom_items_id_seq OWNED BY public.tom_items.id;


--
-- Name: trades; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.trades (
    id integer NOT NULL,
    trade_code integer,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    category public.enum_trades_category DEFAULT 'MAJOR'::public.enum_trades_category NOT NULL,
    trade_name character varying(100) NOT NULL
);


ALTER TABLE public.trades OWNER TO prs_user;

--
-- Name: trades_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.trades_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.trades_id_seq OWNER TO prs_user;

--
-- Name: trades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.trades_id_seq OWNED BY public.trades.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(255) NOT NULL,
    email character varying(255),
    password character varying(255) NOT NULL,
    first_name character varying(50),
    last_name character varying(50),
    role_id integer NOT NULL,
    otp_secret character varying(512),
    status public.enum_users_status DEFAULT 'active'::public.enum_users_status NOT NULL,
    is_password_temporary boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    deleted_at timestamp with time zone,
    department_id integer,
    temp_pass character varying(100),
    supervisor_id integer
);


ALTER TABLE public.users OWNER TO prs_user;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO prs_user;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: vw_dashboard_requisitions; Type: VIEW; Schema: public; Owner: prs_user
--

CREATE VIEW public.vw_dashboard_requisitions AS
 SELECT r.id AS requisition_id,
        CASE
            WHEN ((r.id IS NOT NULL) AND (COALESCE(cs.id, po.id, dr.id, pr.id) IS NULL)) THEN r.id
            WHEN ((cs.id IS NOT NULL) AND (COALESCE(po.id, dr.id, pr.id) IS NULL)) THEN cs.id
            WHEN ((po.id IS NOT NULL) AND (COALESCE(dr.id, pr.id) IS NULL)) THEN po.id
            WHEN ((dr.id IS NOT NULL) AND (pr.id IS NULL)) THEN dr.id
            WHEN (pr.id IS NOT NULL) THEN pr.id
            ELSE NULL::integer
        END AS ref_id,
        CASE
            WHEN (r.id IS NOT NULL) THEN (((
            CASE
                WHEN ((r.status)::text = 'draft'::text) THEN 'RS-TMP-'::text
                ELSE 'RS-'::text
            END || (r.company_code)::text) || (r.rs_letter)::text) || (COALESCE(r.rs_number, r.draft_rs_number))::text)
            ELSE NULL::text
        END AS rs_combined_number,
        CASE
            WHEN (cs.id IS NOT NULL) THEN (((
            CASE
                WHEN ((cs.status)::text = 'draft'::text) THEN 'CS-TMP-'::text
                ELSE 'CS-'::text
            END || (r.company_code)::text) || (cs.cs_letter)::text) || (COALESCE(cs.cs_number, cs.draft_cs_number))::text)
            ELSE NULL::text
        END AS canvass_number,
        CASE
            WHEN (po.id IS NOT NULL) THEN ((('PO-'::text || (r.company_code)::text) || (po.po_letter)::text) || (po.po_number)::text)
            ELSE NULL::text
        END AS po_number,
        CASE
            WHEN (pr.id IS NOT NULL) THEN (((
            CASE
                WHEN (pr.is_draft = true) THEN 'PR-TMP-'::text
                ELSE 'PR-'::text
            END || (r.company_code)::text) || (pr.pr_letter)::text) || (COALESCE(pr.pr_number, pr.draft_pr_number))::text)
            ELSE NULL::text
        END AS pr_number,
        CASE
            WHEN (dr.id IS NOT NULL) THEN (
            CASE
                WHEN (dr.is_draft = true) THEN 'RR-TMP-'::text
                ELSE 'RR-'::text
            END || (COALESCE(dr.dr_number, dr.draft_dr_number))::text)
            ELSE NULL::text
        END AS dr_number,
    concat(u.first_name, ' ', u.last_name) AS requestor_full_name,
    c.name AS company_name,
    p.name AS project_name,
    d.name AS department_name,
    r.type AS ref_type,
    r.status AS ref_status,
    r.created_at AS ref_created_at,
    r.updated_at AS ref_updated_at,
    r.status,
    cs.id AS cs_id,
    po.id AS po_id,
    dr.id AS dr_id,
    pr.id AS pr_id
   FROM ((((((((public.requisitions r
     LEFT JOIN public.canvass_requisitions cs ON ((r.id = cs.requisition_id)))
     LEFT JOIN public.purchase_orders po ON ((r.id = po.requisition_id)))
     LEFT JOIN public.delivery_receipts dr ON ((r.id = dr.requisition_id)))
     LEFT JOIN public.rs_payment_requests pr ON ((r.id = pr.requisition_id)))
     LEFT JOIN public.users u ON ((r.created_by = u.id)))
     LEFT JOIN public.companies c ON ((r.company_id = c.id)))
     LEFT JOIN public.departments d ON ((r.department_id = d.id)))
     LEFT JOIN public.projects p ON ((r.project_id = p.id)));


ALTER TABLE public.vw_dashboard_requisitions OWNER TO prs_user;

--
-- Name: warranties; Type: TABLE; Schema: public; Owner: prs_user
--

CREATE TABLE public.warranties (
    id integer NOT NULL,
    name character varying(255) NOT NULL,
    type character varying(255),
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.warranties OWNER TO prs_user;

--
-- Name: warranties_id_seq; Type: SEQUENCE; Schema: public; Owner: prs_user
--

CREATE SEQUENCE public.warranties_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.warranties_id_seq OWNER TO prs_user;

--
-- Name: warranties_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: prs_user
--

ALTER SEQUENCE public.warranties_id_seq OWNED BY public.warranties.id;


--
-- Name: approval_types id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.approval_types ALTER COLUMN id SET DEFAULT nextval('public.approval_types_id_seq'::regclass);


--
-- Name: association_areas id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.association_areas ALTER COLUMN id SET DEFAULT nextval('public.association_areas_id_seq'::regclass);


--
-- Name: attachment_badges id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.attachment_badges ALTER COLUMN id SET DEFAULT nextval('public.attachment_badges_id_seq'::regclass);


--
-- Name: attachments id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.attachments ALTER COLUMN id SET DEFAULT nextval('public.attachments_id_seq'::regclass);


--
-- Name: audit_logs id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.audit_logs ALTER COLUMN id SET DEFAULT nextval('public.audit_logs_id_seq'::regclass);


--
-- Name: canvass_approvers id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.canvass_approvers ALTER COLUMN id SET DEFAULT nextval('public.canvass_approvers_id_seq'::regclass);


--
-- Name: canvass_item_suppliers id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.canvass_item_suppliers ALTER COLUMN id SET DEFAULT nextval('public.canvass_item_suppliers_id_seq'::regclass);


--
-- Name: canvass_items id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.canvass_items ALTER COLUMN id SET DEFAULT nextval('public.canvass_items_id_seq'::regclass);


--
-- Name: canvass_requisitions id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.canvass_requisitions ALTER COLUMN id SET DEFAULT nextval('public.canvass_requisitions_id_seq'::regclass);


--
-- Name: comment_badges id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.comment_badges ALTER COLUMN id SET DEFAULT nextval('public.comment_badges_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: companies id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.companies ALTER COLUMN id SET DEFAULT nextval('public.companies_id_seq'::regclass);


--
-- Name: delivery_receipt_invoices id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.delivery_receipt_invoices ALTER COLUMN id SET DEFAULT nextval('public.delivery_receipt_invoices_id_seq'::regclass);


--
-- Name: delivery_receipt_items id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.delivery_receipt_items ALTER COLUMN id SET DEFAULT nextval('public.delivery_receipt_items_id_seq'::regclass);


--
-- Name: delivery_receipt_items_history id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.delivery_receipt_items_history ALTER COLUMN id SET DEFAULT nextval('public.delivery_receipt_items_history_id_seq'::regclass);


--
-- Name: delivery_receipts id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.delivery_receipts ALTER COLUMN id SET DEFAULT nextval('public.delivery_receipts_id_seq'::regclass);


--
-- Name: department_approvals id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.department_approvals ALTER COLUMN id SET DEFAULT nextval('public.department_approvals_id_seq'::regclass);


--
-- Name: department_association_approvals id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.department_association_approvals ALTER COLUMN id SET DEFAULT nextval('public.department_association_approvals_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.departments ALTER COLUMN id SET DEFAULT nextval('public.departments_id_seq'::regclass);


--
-- Name: force_close_logs id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.force_close_logs ALTER COLUMN id SET DEFAULT nextval('public.force_close_logs_id_seq'::regclass);


--
-- Name: gate_passes id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.gate_passes ALTER COLUMN id SET DEFAULT nextval('public.gate_passes_id_seq'::regclass);


--
-- Name: histories id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.histories ALTER COLUMN id SET DEFAULT nextval('public.histories_id_seq'::regclass);


--
-- Name: invoice_report_histories id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.invoice_report_histories ALTER COLUMN id SET DEFAULT nextval('public.invoice_report_histories_id_seq'::regclass);


--
-- Name: invoice_reports id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.invoice_reports ALTER COLUMN id SET DEFAULT nextval('public.invoice_reports_id_seq'::regclass);


--
-- Name: items id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.items ALTER COLUMN id SET DEFAULT nextval('public.items_id_seq'::regclass);


--
-- Name: leaves id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.leaves ALTER COLUMN id SET DEFAULT nextval('public.leaves_id_seq'::regclass);


--
-- Name: non_ofm_items id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.non_ofm_items ALTER COLUMN id SET DEFAULT nextval('public.non_ofm_items_id_seq'::regclass);


--
-- Name: non_requisition_approvers id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.non_requisition_approvers ALTER COLUMN id SET DEFAULT nextval('public.non_requisition_approvers_id_seq'::regclass);


--
-- Name: non_requisition_histories id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.non_requisition_histories ALTER COLUMN id SET DEFAULT nextval('public.non_requisition_histories_id_seq'::regclass);


--
-- Name: non_requisition_items id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.non_requisition_items ALTER COLUMN id SET DEFAULT nextval('public.non_requisition_items_id_seq'::regclass);


--
-- Name: non_requisitions id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.non_requisitions ALTER COLUMN id SET DEFAULT nextval('public.non_requisitions_id_seq'::regclass);


--
-- Name: note_badges id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.note_badges ALTER COLUMN id SET DEFAULT nextval('public.note_badges_id_seq'::regclass);


--
-- Name: notes id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.notes ALTER COLUMN id SET DEFAULT nextval('public.notes_id_seq'::regclass);


--
-- Name: notifications id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.notifications ALTER COLUMN id SET DEFAULT nextval('public.notifications_id_seq'::regclass);


--
-- Name: ofm_item_lists id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.ofm_item_lists ALTER COLUMN id SET DEFAULT nextval('public.ofm_item_lists_id_seq'::regclass);


--
-- Name: ofm_list_items id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.ofm_list_items ALTER COLUMN id SET DEFAULT nextval('public.ofm_list_items_id_seq'::regclass);


--
-- Name: permissions id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.permissions ALTER COLUMN id SET DEFAULT nextval('public.permissions_id_seq'::regclass);


--
-- Name: project_approvals id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.project_approvals ALTER COLUMN id SET DEFAULT nextval('public.project_approvals_id_seq'::regclass);


--
-- Name: project_companies id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.project_companies ALTER COLUMN id SET DEFAULT nextval('public.project_companies_id_seq'::regclass);


--
-- Name: projects id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.projects ALTER COLUMN id SET DEFAULT nextval('public.projects_id_seq'::regclass);


--
-- Name: projects_trades id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.projects_trades ALTER COLUMN id SET DEFAULT nextval('public.projects_trades_id_seq'::regclass);


--
-- Name: prs_timescaledb_status id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.prs_timescaledb_status ALTER COLUMN id SET DEFAULT nextval('public.prs_timescaledb_status_id_seq'::regclass);


--
-- Name: purchase_order_approvers id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.purchase_order_approvers ALTER COLUMN id SET DEFAULT nextval('public.purchase_order_approvers_id_seq'::regclass);


--
-- Name: purchase_order_cancelled_items id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.purchase_order_cancelled_items ALTER COLUMN id SET DEFAULT nextval('public.purchase_order_cancelled_items_id_seq'::regclass);


--
-- Name: purchase_order_items id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.purchase_order_items ALTER COLUMN id SET DEFAULT nextval('public.purchase_order_items_id_seq'::regclass);


--
-- Name: purchase_orders id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.purchase_orders ALTER COLUMN id SET DEFAULT nextval('public.purchase_orders_id_seq'::regclass);


--
-- Name: requisition_approvers id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_approvers ALTER COLUMN id SET DEFAULT nextval('public.requisition_approvers_id_seq'::regclass);


--
-- Name: requisition_badges id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_badges ALTER COLUMN id SET DEFAULT nextval('public.requisition_badges_id_seq'::regclass);


--
-- Name: requisition_canvass_histories id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_canvass_histories ALTER COLUMN id SET DEFAULT nextval('public.requisition_canvass_histories_id_seq'::regclass);


--
-- Name: requisition_delivery_histories id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_delivery_histories ALTER COLUMN id SET DEFAULT nextval('public.requisition_delivery_histories_id_seq'::regclass);


--
-- Name: requisition_item_histories id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_item_histories ALTER COLUMN id SET DEFAULT nextval('public.requisition_item_histories_id_seq'::regclass);


--
-- Name: requisition_item_lists id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_item_lists ALTER COLUMN id SET DEFAULT nextval('public.requisition_item_lists_id_seq'::regclass);


--
-- Name: requisition_order_histories id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_order_histories ALTER COLUMN id SET DEFAULT nextval('public.requisition_order_histories_id_seq'::regclass);


--
-- Name: requisition_payment_histories id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_payment_histories ALTER COLUMN id SET DEFAULT nextval('public.requisition_payment_histories_id_seq'::regclass);


--
-- Name: requisition_return_histories id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_return_histories ALTER COLUMN id SET DEFAULT nextval('public.requisition_return_histories_id_seq'::regclass);


--
-- Name: requisitions id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisitions ALTER COLUMN id SET DEFAULT nextval('public.requisitions_id_seq'::regclass);


--
-- Name: role_permissions id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.role_permissions ALTER COLUMN id SET DEFAULT nextval('public.role_permissions_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: rs_payment_request_approvers id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.rs_payment_request_approvers ALTER COLUMN id SET DEFAULT nextval('public.rs_payment_request_approvers_id_seq'::regclass);


--
-- Name: rs_payment_requests id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.rs_payment_requests ALTER COLUMN id SET DEFAULT nextval('public.rs_payment_requests_id_seq'::regclass);


--
-- Name: steelbars id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.steelbars ALTER COLUMN id SET DEFAULT nextval('public.steelbars_id_seq'::regclass);


--
-- Name: suppliers id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.suppliers ALTER COLUMN id SET DEFAULT nextval('public.suppliers_id_seq'::regclass);


--
-- Name: syncs id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.syncs ALTER COLUMN id SET DEFAULT nextval('public.syncs_id_seq'::regclass);


--
-- Name: timescaledb_migration_status id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.timescaledb_migration_status ALTER COLUMN id SET DEFAULT nextval('public.timescaledb_migration_status_id_seq'::regclass);


--
-- Name: tom_items id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.tom_items ALTER COLUMN id SET DEFAULT nextval('public.tom_items_id_seq'::regclass);


--
-- Name: trades id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.trades ALTER COLUMN id SET DEFAULT nextval('public.trades_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: warranties id; Type: DEFAULT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.warranties ALTER COLUMN id SET DEFAULT nextval('public.warranties_id_seq'::regclass);


--
-- Data for Name: hypertable; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.hypertable (id, schema_name, table_name, associated_schema_name, associated_table_prefix, num_dimensions, chunk_sizing_func_schema, chunk_sizing_func_name, chunk_target_size, compression_state, compressed_hypertable_id, status) FROM stdin;
6	public	notifications	_timescaledb_internal	_hyper_6	1	_timescaledb_functions	calculate_chunk_interval	0	1	39	0
4	public	force_close_logs	_timescaledb_internal	_hyper_4	1	_timescaledb_functions	calculate_chunk_interval	0	1	40	0
7	public	notes	_timescaledb_internal	_hyper_7	1	_timescaledb_functions	calculate_chunk_interval	0	1	42	0
11	public	histories	_timescaledb_internal	_hyper_11	1	_timescaledb_functions	calculate_chunk_interval	0	1	43	0
15	public	requisition_item_histories	_timescaledb_internal	_hyper_15	1	_timescaledb_functions	calculate_chunk_interval	0	1	44	0
12	public	requisition_canvass_histories	_timescaledb_internal	_hyper_12	1	_timescaledb_functions	calculate_chunk_interval	0	1	45	0
1	public	requisitions	_timescaledb_internal	_hyper_1	1	_timescaledb_functions	calculate_chunk_interval	0	1	52	0
2	public	purchase_orders	_timescaledb_internal	_hyper_2	1	_timescaledb_functions	calculate_chunk_interval	0	1	53	0
3	public	delivery_receipts	_timescaledb_internal	_hyper_3	1	_timescaledb_functions	calculate_chunk_interval	0	1	54	0
17	public	canvass_items	_timescaledb_internal	_hyper_17	1	_timescaledb_functions	calculate_chunk_interval	0	1	59	0
13	public	canvass_item_suppliers	_timescaledb_internal	_hyper_13	1	_timescaledb_functions	calculate_chunk_interval	0	1	60	0
14	public	canvass_approvers	_timescaledb_internal	_hyper_14	1	_timescaledb_functions	calculate_chunk_interval	0	1	61	0
18	public	purchase_order_items	_timescaledb_internal	_hyper_18	1	_timescaledb_functions	calculate_chunk_interval	0	1	62	0
8	public	requisition_badges	_timescaledb_internal	_hyper_8	1	_timescaledb_functions	calculate_chunk_interval	0	1	70	0
9	public	requisition_approvers	_timescaledb_internal	_hyper_9	1	_timescaledb_functions	calculate_chunk_interval	0	1	71	0
10	public	attachments	_timescaledb_internal	_hyper_10	1	_timescaledb_functions	calculate_chunk_interval	0	1	72	0
16	public	requisition_item_lists	_timescaledb_internal	_hyper_16	1	_timescaledb_functions	calculate_chunk_interval	0	1	73	0
26	public	invoice_report_histories	_timescaledb_internal	_hyper_26	1	_timescaledb_functions	calculate_chunk_interval	0	0	\N	0
21	public	requisition_order_histories	_timescaledb_internal	_hyper_21	1	_timescaledb_functions	calculate_chunk_interval	0	1	46	0
22	public	requisition_delivery_histories	_timescaledb_internal	_hyper_22	1	_timescaledb_functions	calculate_chunk_interval	0	1	47	0
23	public	requisition_payment_histories	_timescaledb_internal	_hyper_23	1	_timescaledb_functions	calculate_chunk_interval	0	1	48	0
24	public	requisition_return_histories	_timescaledb_internal	_hyper_24	1	_timescaledb_functions	calculate_chunk_interval	0	1	49	0
25	public	non_requisition_histories	_timescaledb_internal	_hyper_25	1	_timescaledb_functions	calculate_chunk_interval	0	1	50	0
29	public	delivery_receipt_items_history	_timescaledb_internal	_hyper_29	1	_timescaledb_functions	calculate_chunk_interval	0	1	51	0
28	public	delivery_receipt_items	_timescaledb_internal	_hyper_28	1	_timescaledb_functions	calculate_chunk_interval	0	1	55	0
30	public	rs_payment_requests	_timescaledb_internal	_hyper_30	1	_timescaledb_functions	calculate_chunk_interval	0	1	56	0
31	public	rs_payment_request_approvers	_timescaledb_internal	_hyper_31	1	_timescaledb_functions	calculate_chunk_interval	0	1	57	0
32	public	canvass_requisitions	_timescaledb_internal	_hyper_32	1	_timescaledb_functions	calculate_chunk_interval	0	1	58	0
19	public	purchase_order_approvers	_timescaledb_internal	_hyper_19	1	_timescaledb_functions	calculate_chunk_interval	0	1	63	0
20	public	non_requisitions	_timescaledb_internal	_hyper_20	1	_timescaledb_functions	calculate_chunk_interval	0	1	64	0
33	public	non_requisition_approvers	_timescaledb_internal	_hyper_33	1	_timescaledb_functions	calculate_chunk_interval	0	1	65	0
34	public	non_requisition_items	_timescaledb_internal	_hyper_34	1	_timescaledb_functions	calculate_chunk_interval	0	1	66	0
35	public	delivery_receipt_invoices	_timescaledb_internal	_hyper_35	1	_timescaledb_functions	calculate_chunk_interval	0	1	67	0
36	public	invoice_reports	_timescaledb_internal	_hyper_36	1	_timescaledb_functions	calculate_chunk_interval	0	1	68	0
38	_timescaledb_internal	_compressed_hypertable_38	_timescaledb_internal	_hyper_38	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
5	public	audit_logs	_timescaledb_internal	_hyper_5	1	_timescaledb_functions	calculate_chunk_interval	0	1	38	0
39	_timescaledb_internal	_compressed_hypertable_39	_timescaledb_internal	_hyper_39	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
40	_timescaledb_internal	_compressed_hypertable_40	_timescaledb_internal	_hyper_40	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
41	_timescaledb_internal	_compressed_hypertable_41	_timescaledb_internal	_hyper_41	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
27	public	comments	_timescaledb_internal	_hyper_27	1	_timescaledb_functions	calculate_chunk_interval	0	1	41	0
42	_timescaledb_internal	_compressed_hypertable_42	_timescaledb_internal	_hyper_42	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
43	_timescaledb_internal	_compressed_hypertable_43	_timescaledb_internal	_hyper_43	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
44	_timescaledb_internal	_compressed_hypertable_44	_timescaledb_internal	_hyper_44	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
45	_timescaledb_internal	_compressed_hypertable_45	_timescaledb_internal	_hyper_45	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
46	_timescaledb_internal	_compressed_hypertable_46	_timescaledb_internal	_hyper_46	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
47	_timescaledb_internal	_compressed_hypertable_47	_timescaledb_internal	_hyper_47	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
48	_timescaledb_internal	_compressed_hypertable_48	_timescaledb_internal	_hyper_48	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
49	_timescaledb_internal	_compressed_hypertable_49	_timescaledb_internal	_hyper_49	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
50	_timescaledb_internal	_compressed_hypertable_50	_timescaledb_internal	_hyper_50	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
51	_timescaledb_internal	_compressed_hypertable_51	_timescaledb_internal	_hyper_51	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
52	_timescaledb_internal	_compressed_hypertable_52	_timescaledb_internal	_hyper_52	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
53	_timescaledb_internal	_compressed_hypertable_53	_timescaledb_internal	_hyper_53	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
54	_timescaledb_internal	_compressed_hypertable_54	_timescaledb_internal	_hyper_54	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
55	_timescaledb_internal	_compressed_hypertable_55	_timescaledb_internal	_hyper_55	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
56	_timescaledb_internal	_compressed_hypertable_56	_timescaledb_internal	_hyper_56	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
57	_timescaledb_internal	_compressed_hypertable_57	_timescaledb_internal	_hyper_57	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
58	_timescaledb_internal	_compressed_hypertable_58	_timescaledb_internal	_hyper_58	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
59	_timescaledb_internal	_compressed_hypertable_59	_timescaledb_internal	_hyper_59	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
60	_timescaledb_internal	_compressed_hypertable_60	_timescaledb_internal	_hyper_60	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
61	_timescaledb_internal	_compressed_hypertable_61	_timescaledb_internal	_hyper_61	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
62	_timescaledb_internal	_compressed_hypertable_62	_timescaledb_internal	_hyper_62	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
63	_timescaledb_internal	_compressed_hypertable_63	_timescaledb_internal	_hyper_63	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
64	_timescaledb_internal	_compressed_hypertable_64	_timescaledb_internal	_hyper_64	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
65	_timescaledb_internal	_compressed_hypertable_65	_timescaledb_internal	_hyper_65	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
66	_timescaledb_internal	_compressed_hypertable_66	_timescaledb_internal	_hyper_66	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
67	_timescaledb_internal	_compressed_hypertable_67	_timescaledb_internal	_hyper_67	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
68	_timescaledb_internal	_compressed_hypertable_68	_timescaledb_internal	_hyper_68	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
69	_timescaledb_internal	_compressed_hypertable_69	_timescaledb_internal	_hyper_69	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
37	public	purchase_order_cancelled_items	_timescaledb_internal	_hyper_37	1	_timescaledb_functions	calculate_chunk_interval	0	1	69	0
70	_timescaledb_internal	_compressed_hypertable_70	_timescaledb_internal	_hyper_70	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
71	_timescaledb_internal	_compressed_hypertable_71	_timescaledb_internal	_hyper_71	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
72	_timescaledb_internal	_compressed_hypertable_72	_timescaledb_internal	_hyper_72	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
73	_timescaledb_internal	_compressed_hypertable_73	_timescaledb_internal	_hyper_73	0	_timescaledb_functions	calculate_chunk_interval	0	2	\N	0
\.


--
-- Data for Name: chunk; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.chunk (id, hypertable_id, schema_name, table_name, compressed_chunk_id, dropped, status, osm_chunk, creation_time) FROM stdin;
\.


--
-- Data for Name: chunk_column_stats; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.chunk_column_stats (id, hypertable_id, chunk_id, column_name, range_start, range_end, valid) FROM stdin;
\.


--
-- Data for Name: dimension; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.dimension (id, hypertable_id, column_name, column_type, aligned, num_slices, partitioning_func_schema, partitioning_func, interval_length, compress_interval_length, integer_now_func_schema, integer_now_func) FROM stdin;
1	1	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
2	2	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
3	3	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
4	4	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
5	5	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
6	6	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
7	7	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
8	8	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
9	9	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
10	10	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
11	11	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
12	12	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
13	13	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
14	14	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
15	15	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
16	16	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
17	17	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
18	18	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
19	19	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
20	20	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
21	21	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
22	22	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
23	23	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
24	24	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
25	25	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
26	26	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
27	27	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
28	28	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
29	29	created_at	timestamp with time zone	t	\N	\N	\N	604800000000	\N	\N	\N
30	30	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
31	31	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
32	32	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
33	33	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
34	34	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
35	35	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
36	36	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
37	37	created_at	timestamp with time zone	t	\N	\N	\N	2592000000000	\N	\N	\N
\.


--
-- Data for Name: dimension_slice; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.dimension_slice (id, dimension_id, range_start, range_end) FROM stdin;
\.


--
-- Data for Name: chunk_constraint; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.chunk_constraint (chunk_id, dimension_slice_id, constraint_name, hypertable_constraint_name) FROM stdin;
\.


--
-- Data for Name: chunk_index; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.chunk_index (chunk_id, index_name, hypertable_id, hypertable_index_name) FROM stdin;
\.


--
-- Data for Name: compression_chunk_size; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.compression_chunk_size (chunk_id, compressed_chunk_id, uncompressed_heap_size, uncompressed_toast_size, uncompressed_index_size, compressed_heap_size, compressed_toast_size, compressed_index_size, numrows_pre_compression, numrows_post_compression, numrows_frozen_immediately) FROM stdin;
\.


--
-- Data for Name: compression_settings; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.compression_settings (relid, compress_relid, segmentby, orderby, orderby_desc, orderby_nullsfirst) FROM stdin;
public.audit_logs	\N	{action_type}	{id,created_at,module}	{f,t,f}	{f,t,f}
public.notifications	\N	{type}	{id,created_at,recipient_user_ids,recipient_role_id}	{f,t,f,f}	{f,t,f,f}
public.force_close_logs	\N	{requisition_id}	{id,created_at,user_id,scenario_type}	{f,t,f,f}	{f,t,f,f}
public.comments	\N	\N	{id,created_at}	{f,t}	{f,t}
public.notes	\N	{model}	{id,created_at}	{f,t}	{f,t}
public.histories	\N	{item_id}	{id,created_at,department_id,project_id,company_id,rs_letter}	{f,t,f,f,f,f}	{f,t,f,f,f,f}
public.requisition_item_histories	\N	\N	{id,created_at}	{f,t}	{f,t}
public.requisition_canvass_histories	\N	{requisition_item_list_id}	{id,created_at}	{f,t}	{f,t}
public.requisition_order_histories	\N	\N	{id,created_at}	{f,t}	{f,t}
public.requisition_delivery_histories	\N	\N	{id,created_at}	{f,t}	{f,t}
public.requisition_payment_histories	\N	\N	{id,created_at}	{f,t}	{f,t}
public.requisition_return_histories	\N	\N	{id,created_at}	{f,t}	{f,t}
public.non_requisition_histories	\N	{non_requisition_id}	{id,created_at,updated_at,approver_id,status}	{f,t,f,f,f}	{f,t,f,f,f}
public.delivery_receipt_items_history	\N	\N	{id,created_at}	{f,t}	{f,t}
public.requisitions	\N	{company_code}	{id,created_at,force_closed_at,status,force_close_scenario,force_closed_by}	{f,t,f,f,f,f}	{f,t,f,f,f,f}
public.purchase_orders	\N	{po_number}	{id,created_at,status,canvass_requisition_id,requisition_id,supplier_id,po_letter}	{f,t,f,f,f,f,f}	{f,t,f,f,f,f,f}
public.delivery_receipts	\N	{requisition_id}	{id,created_at,cancelled_by,cancelled_at}	{f,t,f,f}	{f,t,f,f}
public.delivery_receipt_items	\N	\N	{id,created_at}	{f,t}	{f,t}
public.rs_payment_requests	\N	{cancelled_at}	{id,created_at,cancelled_by}	{f,t,f}	{f,t,f}
public.rs_payment_request_approvers	\N	\N	{id,created_at}	{f,t}	{f,t}
public.canvass_requisitions	\N	{requisition_id}	{id,created_at,cancelled_by,cancelled_at,status}	{f,t,f,f,f}	{f,t,f,f,f}
public.canvass_items	\N	{canvass_requisition_id}	{id,created_at,requisition_id,requisition_item_list_id}	{f,t,f,f}	{f,t,f,f}
public.canvass_item_suppliers	\N	{canvass_item_id}	{id,created_at,order,supplier_id}	{f,t,f,f}	{f,t,f,f}
public.canvass_approvers	\N	{canvass_requisition_id}	{id,created_at,user_id,role_id,level}	{f,t,f,f,f}	{f,t,f,f,f}
public.purchase_order_items	\N	{purchase_order_id}	{id,created_at,requisition_item_list_id,canvass_item_supplier_id,canvass_item_id}	{f,t,f,f,f}	{f,t,f,f,f}
public.purchase_order_approvers	\N	{purchase_order_id}	{id,created_at,alt_approver_id,status,user_id,role_id,level}	{f,t,f,f,f,f,f}	{f,t,f,f,f,f,f}
public.non_requisitions	\N	{non_rs_letter}	{id,created_at,invoice_no,status,created_by,charge_to,draft_non_rs_number,non_rs_number}	{f,t,f,f,f,f,f,f}	{f,t,f,f,f,f,f,f}
public.non_requisition_approvers	\N	{non_requisition_id}	{id,created_at,user_id,status,role_id}	{f,t,f,f,f}	{f,t,f,f,f}
public.non_requisition_items	\N	{non_requisition_id}	{id,created_at,name}	{f,t,f}	{f,t,f}
public.delivery_receipt_invoices	\N	\N	{id,created_at}	{f,t}	{f,t}
public.invoice_reports	\N	{company_code}	{id,created_at,cancelled_at,cancelled_by}	{f,t,f,f}	{f,t,f,f}
public.purchase_order_cancelled_items	\N	{purchase_order_id}	{id,created_at,requisition_id,canvass_item_id,canvass_requisition_id,supplier_id}	{f,t,f,f,f,f}	{f,t,f,f,f,f}
public.requisition_badges	\N	{requisition_id}	{id,created_at}	{f,t}	{f,t}
public.requisition_approvers	\N	\N	{id,created_at}	{f,t}	{f,t}
public.attachments	\N	{model}	{id,created_at}	{f,t}	{f,t}
public.requisition_item_lists	\N	\N	{id,created_at}	{f,t}	{f,t}
\.


--
-- Data for Name: continuous_agg; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.continuous_agg (mat_hypertable_id, raw_hypertable_id, parent_mat_hypertable_id, user_view_schema, user_view_name, partial_view_schema, partial_view_name, direct_view_schema, direct_view_name, materialized_only, finalized) FROM stdin;
\.


--
-- Data for Name: continuous_agg_migrate_plan; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.continuous_agg_migrate_plan (mat_hypertable_id, start_ts, end_ts, user_view_definition) FROM stdin;
\.


--
-- Data for Name: continuous_agg_migrate_plan_step; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.continuous_agg_migrate_plan_step (mat_hypertable_id, step_id, status, start_ts, end_ts, type, config) FROM stdin;
\.


--
-- Data for Name: continuous_aggs_bucket_function; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.continuous_aggs_bucket_function (mat_hypertable_id, bucket_func, bucket_width, bucket_origin, bucket_offset, bucket_timezone, bucket_fixed_width) FROM stdin;
\.


--
-- Data for Name: continuous_aggs_hypertable_invalidation_log; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.continuous_aggs_hypertable_invalidation_log (hypertable_id, lowest_modified_value, greatest_modified_value) FROM stdin;
\.


--
-- Data for Name: continuous_aggs_invalidation_threshold; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.continuous_aggs_invalidation_threshold (hypertable_id, watermark) FROM stdin;
\.


--
-- Data for Name: continuous_aggs_materialization_invalidation_log; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.continuous_aggs_materialization_invalidation_log (materialization_id, lowest_modified_value, greatest_modified_value) FROM stdin;
\.


--
-- Data for Name: continuous_aggs_watermark; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.continuous_aggs_watermark (mat_hypertable_id, watermark) FROM stdin;
\.


--
-- Data for Name: metadata; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.metadata (key, value, include_in_telemetry) FROM stdin;
install_timestamp	2025-06-29 23:06:43.681543+00	t
timescaledb_version	2.20.3	f
\.


--
-- Data for Name: tablespace; Type: TABLE DATA; Schema: _timescaledb_catalog; Owner: prs_user
--

COPY _timescaledb_catalog.tablespace (id, hypertable_id, tablespace_name) FROM stdin;
\.


--
-- Data for Name: bgw_job; Type: TABLE DATA; Schema: _timescaledb_config; Owner: prs_user
--

COPY _timescaledb_config.bgw_job (id, application_name, schedule_interval, max_runtime, max_retries, retry_period, proc_schema, proc_name, owner, scheduled, fixed_schedule, initial_start, hypertable_id, config, check_schema, check_name, timezone) FROM stdin;
1000	Columnstore Policy [1000]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	5	{"hypertable_id": 5, "compress_after": "30 days"}	_timescaledb_functions	policy_compression_check	\N
1001	Columnstore Policy [1001]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	6	{"hypertable_id": 6, "compress_after": "30 days"}	_timescaledb_functions	policy_compression_check	\N
1002	Columnstore Policy [1002]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	4	{"hypertable_id": 4, "compress_after": "30 days"}	_timescaledb_functions	policy_compression_check	\N
1003	Columnstore Policy [1003]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	27	{"hypertable_id": 27, "compress_after": "90 days"}	_timescaledb_functions	policy_compression_check	\N
1004	Columnstore Policy [1004]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	7	{"hypertable_id": 7, "compress_after": "90 days"}	_timescaledb_functions	policy_compression_check	\N
1005	Columnstore Policy [1005]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	11	{"hypertable_id": 11, "compress_after": "90 days"}	_timescaledb_functions	policy_compression_check	\N
1006	Columnstore Policy [1006]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	15	{"hypertable_id": 15, "compress_after": "90 days"}	_timescaledb_functions	policy_compression_check	\N
1007	Columnstore Policy [1007]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	12	{"hypertable_id": 12, "compress_after": "90 days"}	_timescaledb_functions	policy_compression_check	\N
1008	Columnstore Policy [1008]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	21	{"hypertable_id": 21, "compress_after": "90 days"}	_timescaledb_functions	policy_compression_check	\N
1009	Columnstore Policy [1009]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	22	{"hypertable_id": 22, "compress_after": "90 days"}	_timescaledb_functions	policy_compression_check	\N
1010	Columnstore Policy [1010]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	23	{"hypertable_id": 23, "compress_after": "90 days"}	_timescaledb_functions	policy_compression_check	\N
1011	Columnstore Policy [1011]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	24	{"hypertable_id": 24, "compress_after": "90 days"}	_timescaledb_functions	policy_compression_check	\N
1012	Columnstore Policy [1012]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	25	{"hypertable_id": 25, "compress_after": "90 days"}	_timescaledb_functions	policy_compression_check	\N
1013	Columnstore Policy [1013]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	29	{"hypertable_id": 29, "compress_after": "90 days"}	_timescaledb_functions	policy_compression_check	\N
1014	Columnstore Policy [1014]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	1	{"hypertable_id": 1, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1015	Columnstore Policy [1015]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	2	{"hypertable_id": 2, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1016	Columnstore Policy [1016]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	3	{"hypertable_id": 3, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1017	Columnstore Policy [1017]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	28	{"hypertable_id": 28, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1018	Columnstore Policy [1018]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	30	{"hypertable_id": 30, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1019	Columnstore Policy [1019]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	31	{"hypertable_id": 31, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1020	Columnstore Policy [1020]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	32	{"hypertable_id": 32, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1021	Columnstore Policy [1021]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	17	{"hypertable_id": 17, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1022	Columnstore Policy [1022]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	13	{"hypertable_id": 13, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1023	Columnstore Policy [1023]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	14	{"hypertable_id": 14, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1024	Columnstore Policy [1024]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	18	{"hypertable_id": 18, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1025	Columnstore Policy [1025]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	19	{"hypertable_id": 19, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1026	Columnstore Policy [1026]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	20	{"hypertable_id": 20, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1027	Columnstore Policy [1027]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	33	{"hypertable_id": 33, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1028	Columnstore Policy [1028]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	34	{"hypertable_id": 34, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1029	Columnstore Policy [1029]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	35	{"hypertable_id": 35, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1030	Columnstore Policy [1030]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	36	{"hypertable_id": 36, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1031	Columnstore Policy [1031]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	37	{"hypertable_id": 37, "compress_after": "6 mons"}	_timescaledb_functions	policy_compression_check	\N
1032	Columnstore Policy [1032]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	8	{"hypertable_id": 8, "compress_after": "1 year"}	_timescaledb_functions	policy_compression_check	\N
1033	Columnstore Policy [1033]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	9	{"hypertable_id": 9, "compress_after": "1 year"}	_timescaledb_functions	policy_compression_check	\N
1034	Columnstore Policy [1034]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	10	{"hypertable_id": 10, "compress_after": "1 year"}	_timescaledb_functions	policy_compression_check	\N
1035	Columnstore Policy [1035]	12:00:00	00:00:00	-1	01:00:00	_timescaledb_functions	policy_compression	prs_user	t	f	\N	16	{"hypertable_id": 16, "compress_after": "1 year"}	_timescaledb_functions	policy_compression_check	\N
\.


--
-- Data for Name: _compressed_hypertable_38; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_38  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_39; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_39  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_40; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_40  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_41; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_41  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_42; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_42  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_43; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_43  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_44; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_44  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_45; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_45  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_46; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_46  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_47; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_47  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_48; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_48  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_49; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_49  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_50; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_50  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_51; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_51  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_52; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_52  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_53; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_53  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_54; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_54  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_55; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_55  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_56; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_56  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_57; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_57  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_58; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_58  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_59; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_59  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_60; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_60  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_61; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_61  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_62; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_62  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_63; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_63  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_64; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_64  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_65; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_65  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_66; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_66  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_67; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_67  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_68; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_68  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_69; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_69  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_70; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_70  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_71; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_71  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_72; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_72  FROM stdin;
\.


--
-- Data for Name: _compressed_hypertable_73; Type: TABLE DATA; Schema: _timescaledb_internal; Owner: prs_user
--

COPY _timescaledb_internal._compressed_hypertable_73  FROM stdin;
\.


--
-- Data for Name: SequelizeMeta; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public."SequelizeMeta" (name) FROM stdin;
20241012142206-role-table.js
20241012142235-user-table.js
20241017030624-create-supplier.js
20241023072644-create-attachment.js
20241028032105-company-table.js
20241028073059-create-comment.js
20241103121935-sync-table.js
20241104003325-permission-table.js
20241104003438-role-permission-table.js
20241104072218-project-table.js
20241104074137-approver-table.js
20241104144511-department-table.js
20241105092442-create-item.js
20241108023732-add-unique-department-migration.js
20241111060607-user-department.js
20241111145607-update-approval-order-to-sting.js
20241112025956-create-comment-badge.js
20241112063649-notification.js
20241113021658-create-attachment-badge.js
20241113054253-user-temp-password.js
20241113065241-alter-comment-and-attachment-badge.js
20241113074425-alter-supplier-update-columns.js
20241113075748-alter-company-code.js
20241113122910-create-audit-logs-table.js
20241114051428-company-department.js
20241114120015-project-company-code.js
20241114122138-project-column-update.js
20241114141825-remove-companyId-department.js
20241118011523-alter-company-code-migration.js
20241119060809-email-allow-null.js
20241120134521-create-trade.js
20241120142514-create-ofm-item-list.js
20241120145221-create-non-ofm-items.js
20241121090007-alter-trade-name.js
20241121111047-add-gfq-and-trade-code-to-items-table.js
20241121142103-create-ofm-list-items.js
20241125001842-remove-company-department.js
20241125030212-remove-dept-supervisor.js
20241125030302-add-department-approvers.js
20241125062914-remove-start-end-project.js
20241125063418-create-requisitions-table.js
20241125064011-company-category.js
20241125064547-rename-manager-depthead.js
20241125082949-user-supervisor-migration.js
20241126052754-remove-dept-approvers.js
20241126062225-create-approval-types.js
20241126064859-remove-legacy-approver.js
20241126071539-dept-approval.js
20241127021235-create-requisition-item-lists.js
20241127075948-add-requisition-type.js
20241127093626-alter-requisition-item-lists.js
20241128034207-proj-approval.js
20241128071029-create-tom-items.js
20241129020703-alter-requisition-item-list-add-account-code.js
20241201054925-alter-requisition-add-draft-rs-number.js
20241202030407-add-trade-category.js
20241202034305-remove-unique-trade-name.js
20241202052415-project-trade.js
20241204074738-alter-requisition-add-charge-to-id.js
20241206084357-department-assoc-table.js
20241207012025-create-requisition-approvers-new.js
20241207104942-create-requisition-approvers.js
20241210053256-project-address.js
20241210073339-company-area.js
20241210163845-add-remaining-gfq-in-items.js
20241211224247-create-history.js
20250102062527-alter-rs-company-code.js
20250103024129-alter-itemname-ofm.js
20250106084436-add-ofm-list-id.js
20250107104540-alter-tom-items-table.js
20250110104851-canvass-table.js
20250110105109-canvass-item-table.js
20250110105233-canvass-approvers-table.js
20250110110201-canvass-item-supplier.js
20250114053727-create-requisition-badges.js
20250114111127-add-notifications-meta-data.js
20250114232021-create-delivery-receipts.js
20250115091623-alter-non-ofm-items-table.js
20250116032016-add-supplier-type.js
20250116064717-create-delivery-receipt-items-table.js
20250116090028-create-leaves.js
20250116093919-remove-status-column-in-delivery-receipts-table.js
20250116094247-modify-po-column-in-delivery-receipts-table.js
20250116134305-add-canvass-disc-value.js
20250116195938-create-delivery-receipt-items-history-table.js
20250119083827-add-requisition-alt-approver-id.js
20250119084305-add-canvass-alt-approver-id.js
20250120070528-add-canvass-reject-reason.js
20250120071453-alter-attachments-file-path.js
20250121012427-create-delivery-receipt-invoices-table.js
20250121082333-alter-histories-rs-number.js
20250121210842-create-notes-table.js
20250122075110-alter-histories.js
20250122075111-alter-histories.js
20250122215853-add-qty-returned-column-in-delivery-receipt-items-table.js
20250123092157-alter-histories-add-rs-letters.js
20250123094555-add-latest-columns-in-delivery-receipts-table.js
20250123134730-alter-canvass-item-supplier-id.js
20250123140107-remove-canvass-item-supplier-id-constraints.js
20250124084248-create-requisition-canvass-history.js
20250124163609-create-requisition-order-history.js
20250124165057-create-requisition-delivery-history.js
20250124170552-create-requisition-payment-history.js
20250124171327-create-requisition-return-history.js
20250124172313-create-requisition-item-history.js
20250125073252-add-steelbars-table.js
20250127082200-create-po-warranty.js
20250128023809-create-purchase-order-table.js
20250128050815-create-purchase-order-item-table.js
20250128051156-create-purchase-order-approver-table.js
20250131165504-add-steelbars-toggle-in-items-table.js
20250202030741-create-rs-payment-request-model.js
20250203082238-add-purchase-order-total_amount.js
20250204085519-create-rs-payment-request-approver.js
20250205080648-alter-steelbars-table.js
20250205230336-add-indices-for-numbers-in-requisitions-table.js
20250212072910-add-on-delete-cascade-to-attachment-badges.js
20250213012658-create-note-badge-table.js
20250213061041-create-non-rs-table.js
20250213061320-create-non-rs-items-table.js
20250213061435-create-non-rs-approvers-table.js
20250214093144-add-timestamps-in-rs-payment-requests-table.js
20250217095256-add-model-id-and-model-indices-in-attachments-table.js
20250217162712-add-indices-in-histories-table.js
20250218062426-add-po-item-id-and-item-type-in-delivery-receipt-items-table.js
20250218235612-create-dashboard-view.js
20250220101517-add-ids-in-requisition-canvass-history-table.js
20250220114103-add-dr-item-id-in-histories-table.js
20250220150422-create-gate-pass.js
20250224022456-remove-supplier-id-foreign-key-in-requisition-canvass-histories.js
20250224123037-add-status-index-in-requisitions-table.js
20250224134024-add-supplier-name-and-lock-in-request-tables.js
20250225084030-create-non-rs-history-table.js
20250225115335-alter-requisition-add-columns.js
20250226044556-add-req-id-and-delivery-date-indices-in-delivery-receipt-table.js
20250227083604-add-last-approver-column-in-rs-payment-requests.js
20250227084230-create-purchase-order-cancelled-items-table.js
20250303033615-add-po-assigned-to-from-rs-fk.js
20250306072424-alter-index-canvass-item-supplier.js
20250310135631-add-missing-fkeys-in-rs-payment-requests.js
20250327021404-alter-companies-code-type.js
20250328030531-change-length-for-notes-in-delivery-receipt-table.js
20250403052220-alter-delivery-receipt-items-unit.js
20250410053047-create-invoice-table.js
20250410071427-alter-canvass-item-enhancement-table.js
20250411011541-alter-non-rs-table.js
20250411031506-alter-table-canvass-item-supplier-qty.js
20250414024720-alter-purchase-order-item-qty.js
20250414071541-add-idx-canvass-items-rsid-status.js
20250414075100-alter-requisition-add-category.js
2025041413726-alter-projects-table-assoc-link.js
20250414235325-alter-non-rs-items-table.js
20250421061431-alter-roles-table.js
20250423113409-alter-purchase-order-new-delivery-address.js
20250423182400-create-project-companies.js
20250424104541-rename-columns-in-project-companies-table.js
20250428055012-alter-ofm-items-gfq-qunatity-with-others.js
20250429090135-change-qty-data-type-in-dr-item-history.js
20250429152000-add-invoice-fields-to-delivery-receipts.js
20250430055900-alter-non-ofm-item-table.js
20250502070627-alter-all-history-model.js
20250502103832-alter-invoice-report-add-status-column.js.js
20250502103832-alter-po-add-discount.js
20250504125215-create-invoice-history-table.js
20250504130644-alter-requisition-approvers.js
20250506055316-change-note-col-to-text-in-dr-items.js
20250515151412-add-status-column-to-delivery-receipts.js
20250515152500-update-invoice-report-statuses.js
20250515153500-alter-supplier-contact-number.js
20250520031802-alter-requisition-approver.js
20250520130600-change-dr-prefix-to-rr.js
20250521031303-add-added-by-column-to-requisition-approver.js
20250527065326-alter-table-canvass_items-table-add-cancelledqty-col.js
20250529031929-add-col-was-cancelled-purchase-order-add.js
20250529064215-change-delivery-invoice-id-to-nullable-in-pr-table.js
20250603082300-add-payment-request-id-in-invoice-reports-table.js
20250604024508-create-table-association-areas.js
20250604093945-add_optional_approver_item_ids.js
20250608134422-add-additional-approver-column-to-requisition-approver.js
20250610120000-add-force-close-schema.js
20250610120001-add-cancelled-status-migration.js
20250616225529-add-column-all-approvers-table.js
20250617032420-add-incidental-cost-columns-in-purchase-orders.js
20250618041130-add-added-by-to-purchase-order-approvers.js
20250619040806-turning-rs-approvers-to-sequence.js
20250620013549-reorder-user-status-enum.js
20250628120000-timescaledb-setup.js
\.


--
-- Data for Name: approval_types; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.approval_types (id, name, code, created_at, updated_at) FROM stdin;
1	Requisition Slip	RS	2025-06-29 23:46:33.777+00	2025-06-29 23:46:33.777+00
2	Canvassing	CV	2025-06-29 23:46:33.777+00	2025-06-29 23:46:33.777+00
3	Purchase Order	PO	2025-06-29 23:46:33.777+00	2025-06-29 23:46:33.777+00
4	Payment Request	PR	2025-06-29 23:46:33.777+00	2025-06-29 23:46:33.777+00
\.


--
-- Data for Name: association_areas; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.association_areas (id, code, name, created_at, updated_at) FROM stdin;
1	MET14	MET 1-4	2025-06-29 23:13:19.144+00	2025-06-29 23:13:19.144+00
2	TMR_TGR_TGH_OTR	TMR / TGR / TGH / OTR	2025-06-29 23:13:19.144+00	2025-06-29 23:13:19.144+00
3	GET_CER_BMCAI	GET / CER / BMCAI	2025-06-29 23:13:19.144+00	2025-06-29 23:13:19.144+00
4	CDC_OFC_MLA_ORTIGAS_VCB_SALES_OFFICE	CDC OFC / MLA / ORTIGAS / VCB / SALES OFFICE	2025-06-29 23:13:19.144+00	2025-06-29 23:13:19.144+00
5	CC10_RADA	CC10 / RADA	2025-06-29 23:13:19.144+00	2025-06-29 23:13:19.144+00
6	PPT12_101X_GCR_CL1_CL3	PPT1&2 / 101X / GCR / CL1 / CL3	2025-06-29 23:13:19.144+00	2025-06-29 23:13:19.144+00
7	ONP_PH1_TNP	ONP / PH1 / TNP	2025-06-29 23:13:19.144+00	2025-06-29 23:13:19.144+00
8	MEM2_NRT	MEM2 / NRT	2025-06-29 23:13:19.144+00	2025-06-29 23:13:19.144+00
\.


--
-- Data for Name: attachment_badges; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.attachment_badges (id, user_id, attachment_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: attachments; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.attachments (id, model, model_id, user_id, file_name, path, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: audit_logs; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.audit_logs (id, action_type, module, description, metadata, created_at) FROM stdin;
\.


--
-- Data for Name: canvass_approvers; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.canvass_approvers (id, canvass_requisition_id, level, user_id, status, role_id, is_adhoc, created_at, updated_at, alt_approver_id, reject_reason, override_by) FROM stdin;
\.


--
-- Data for Name: canvass_item_suppliers; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.canvass_item_suppliers (id, canvass_item_id, supplier_id, term, quantity, "order", unit_price, discount_type, is_selected, created_at, updated_at, supplier_type, discount_value, supplier_name, supplier_name_locked) FROM stdin;
\.


--
-- Data for Name: canvass_items; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.canvass_items (id, canvass_requisition_id, requisition_item_list_id, status, created_at, updated_at, requisition_id, cancelled_qty) FROM stdin;
\.


--
-- Data for Name: canvass_requisitions; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.canvass_requisitions (id, requisition_id, cs_number, cs_letter, draft_cs_number, status, created_at, updated_at, cancelled_at, cancelled_by, cancellation_reason) FROM stdin;
\.


--
-- Data for Name: comment_badges; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.comment_badges (id, user_id, comment_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.comments (id, model, model_id, commented_by, comment, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: companies; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.companies (id, name, initial, tin, address, contact_number, created_at, updated_at, code, category, area_code) FROM stdin;
\.


--
-- Data for Name: delivery_receipt_invoices; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.delivery_receipt_invoices (id, delivery_receipt_id, invoice_no, issued_invoice_date, total_sales, vat_amount, vat_exempted_amount, zero_rated_amount, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: delivery_receipt_items; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.delivery_receipt_items (id, dr_id, po_id, item_id, item_des, qty_ordered, qty_delivered, unit, date_delivered, delivery_status, notes, created_at, updated_at, qty_returned, has_returns, po_item_id, item_type) FROM stdin;
\.


--
-- Data for Name: delivery_receipt_items_history; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.delivery_receipt_items_history (id, delivery_receipt_item_id, qty_ordered, qty_delivered, date_delivered, status, created_at, updated_at, qty_returned) FROM stdin;
\.


--
-- Data for Name: delivery_receipts; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.delivery_receipts (id, requisition_id, company_code, dr_number, supplier, is_draft, draft_dr_number, note, created_at, updated_at, po_id, latest_delivery_date, latest_delivery_status, supplier_name_locked, invoice_id, invoice_number, supplier_delivery_issued_date, issued_date, status, cancelled_at, cancelled_by, cancellation_reason) FROM stdin;
\.


--
-- Data for Name: department_approvals; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.department_approvals (id, department_id, approval_type_code, level, is_optional, approver_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: department_association_approvals; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.department_association_approvals (id, approval_type_code, level, area_code, approver_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.departments (id, name, code, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: force_close_logs; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.force_close_logs (id, requisition_id, user_id, scenario_type, validation_path, quantities_affected, documents_cancelled, po_adjustments, force_close_notes, created_at) FROM stdin;
\.


--
-- Data for Name: gate_passes; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.gate_passes (id, requisition_id, purchase_order_id, gate_pass_number, "createdAt", "updatedAt") FROM stdin;
\.


--
-- Data for Name: histories; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.histories (id, rs_number, item_id, date_requested, quantity_requested, price, quantity_delivered, date_delivered, type, created_at, updated_at, company_id, project_id, department_id, rs_letter, dr_item_id) FROM stdin;
\.


--
-- Data for Name: invoice_report_histories; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.invoice_report_histories (id, requisition_id, purchase_order_id, invoice_report_id, ir_number, supplier_invoice_no, issued_invoice_date, invoice_amount, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: invoice_reports; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.invoice_reports (id, ir_number, ir_draft_number, is_draft, requisition_id, purchase_order_id, company_code, supplier_invoice_no, issued_invoice_date, invoice_amount, note, created_by, created_at, updated_at, status, payment_request_id, cancelled_at, cancelled_by, cancellation_reason) FROM stdin;
\.


--
-- Data for Name: items; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.items (id, item_cd, itm_des, unit, acct_cd, created_at, updated_at, gfq, trade_code, remaining_gfq, is_steelbars) FROM stdin;
\.


--
-- Data for Name: leaves; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.leaves (id, user_id, start_date, end_date, total_days, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: non_ofm_items; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.non_ofm_items (id, item_name, item_type, unit, acct_cd, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: non_requisition_approvers; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.non_requisition_approvers (id, non_requisition_id, level, user_id, alt_approver_id, status, role_id, is_adhoc, created_at, updated_at, override_by) FROM stdin;
\.


--
-- Data for Name: non_requisition_histories; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.non_requisition_histories (id, non_requisition_id, approver_id, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: non_requisition_items; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.non_requisition_items (id, non_requisition_id, name, quantity, amount, discount_value, discount_type, discounted_price, created_at, updated_at, unit) FROM stdin;
\.


--
-- Data for Name: non_requisitions; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.non_requisitions (id, non_rs_letter, non_rs_number, draft_non_rs_number, charge_to, charge_to_id, created_by, invoice_date, status, invoice_no, payable_to, total_amount, total_discount, total_discounted_amount, created_at, updated_at, company_id, project_id, department_id, supplier_id, category, group_discount_type, group_discount_price, supplier_invoice_amount) FROM stdin;
\.


--
-- Data for Name: note_badges; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.note_badges (id, user_id, note_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: notes; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.notes (id, model, model_id, user_name, user_type, comment_type, note, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: notifications; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.notifications (id, title, message, type, recipient_role_id, recipient_user_ids, sender_id, viewed_by, created_at, updated_at, deleted_at, meta_data) FROM stdin;
\.


--
-- Data for Name: ofm_item_lists; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.ofm_item_lists (id, list_name, company_code, department_code, project_code, trade_code, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: ofm_list_items; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.ofm_list_items (id, ofm_list_id, ofm_item_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: permissions; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.permissions (id, module, action, created_at, updated_at) FROM stdin;
1	roles	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
2	users	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
3	users	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
4	users	create	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
5	users	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
6	users	delete	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
7	companies	create	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
8	companies	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
9	companies	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
10	companies	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
11	companies	sync	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
12	companies	delete	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
13	projects	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
14	projects	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
15	projects	sync	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
16	projects	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
17	projects	approval	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
18	projects	delete	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
19	departments	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
20	departments	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
21	departments	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
22	departments	sync	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
23	departments	approval	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
24	suppliers	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
25	suppliers	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
26	suppliers	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
27	suppliers	sync	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
28	suppliers	delete	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
29	ofm_items	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
30	ofm_items	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
31	ofm_items	create	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
32	ofm_items	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
33	ofm_history	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
34	ofm_history	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
35	ofm_items	sync	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
36	ofm_lists	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
37	ofm_lists	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
38	ofm_lists	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
39	non_ofm_items	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
40	non_ofm_items	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
41	non_ofm_items	create	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
42	non_ofm_items	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
43	non_ofm_items	delete	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
44	dashboard	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
45	dashboard	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
46	dashboard	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
47	dashboard	delete	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
48	dashboard	create	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
49	dashboard	approval	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
50	dashboard_history	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
51	dashboard_history	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
52	canvass	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
53	canvass	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
54	canvass	create	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
55	canvass	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
56	canvass	delete	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
57	canvass	approval	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
58	orders	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
59	orders	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
60	orders	create	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
61	orders	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
62	orders	delete	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
63	orders	approval	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
64	delivery	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
65	delivery	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
66	delivery	create	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
67	delivery	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
68	delivery	delete	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
69	payments	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
70	payments	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
71	payments	create	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
72	payments	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
73	payments	delete	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
74	payments	approval	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
75	non_rs_payments	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
76	non_rs_payments	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
77	non_rs_payments	create	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
78	non_rs_payments	update	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
79	non_rs_payments	delete	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
80	non_rs_payments	approval	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
81	audit_logs	view	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
82	audit_logs	get	2025-06-29 23:46:33.576+00	2025-06-29 23:46:33.576+00
83	invoice	create	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
84	invoice	view	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
85	invoice	get	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
86	invoice	update	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
87	invoice	delete	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
\.


--
-- Data for Name: project_approvals; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.project_approvals (id, project_id, approval_type_code, level, is_optional, approver_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: project_companies; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.project_companies (id, project_id, company_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: projects; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.projects (id, code, name, initial, created_at, updated_at, company_code, address, company_id) FROM stdin;
\.


--
-- Data for Name: projects_trades; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.projects_trades (id, project_id, trade_id, engineer_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: prs_timescaledb_status; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.prs_timescaledb_status (id, table_name, is_hypertable, chunk_time_interval, compression_enabled, total_chunks, table_size_pretty, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: purchase_order_approvers; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.purchase_order_approvers (id, purchase_order_id, level, user_id, status, role_id, is_adhoc, alt_approver_id, created_at, updated_at, override_by, added_by) FROM stdin;
\.


--
-- Data for Name: purchase_order_cancelled_items; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.purchase_order_cancelled_items (id, purchase_order_id, requisition_id, canvass_requisition_id, canvass_item_id, requisition_item_list_id, supplier_id, supplier_type, created_at, updated_at, status) FROM stdin;
\.


--
-- Data for Name: purchase_order_items; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.purchase_order_items (id, purchase_order_id, canvass_item_id, requisition_item_list_id, quantity_purchased, canvass_item_supplier_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: purchase_orders; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.purchase_orders (id, po_number, po_letter, requisition_id, canvass_requisition_id, supplier_id, supplier_type, status, delivery_address, terms, warranty_id, deposit_percent, created_at, updated_at, total_amount, total_discount, total_discounted_amount, supplier_name, supplier_name_locked, assigned_to, new_delivery_address, is_new_delivery_address, added_discount, is_added_discount_fixed_amount, is_added_discount_percentage, was_cancelled, system_generated_notes, original_amount, original_quantity, withholding_tax_deduction, delivery_fee, tip, extra_charges) FROM stdin;
\.


--
-- Data for Name: requisition_approvers; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.requisition_approvers (id, requisition_id, model_id, approver_id, level, is_alt_approver, model_type, status, created_at, updated_at, alt_approver_id, is_optional_approver, added_by, optional_approver_item_ids, is_additional_approver, override_by, approver_level) FROM stdin;
\.


--
-- Data for Name: requisition_badges; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.requisition_badges (id, requisition_id, created_by, seen_by, model, model_id, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: requisition_canvass_histories; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.requisition_canvass_histories (id, requisition_id, canvass_number, supplier, item, price, discount, canvass_date, status, created_at, updated_at, requisition_item_list_id, supplier_id, canvass_requisition_id) FROM stdin;
\.


--
-- Data for Name: requisition_delivery_histories; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.requisition_delivery_histories (id, requisition_id, dr_number, supplier, date_ordered, quantity_ordered, quantity_delivered, date_delivered, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: requisition_item_histories; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.requisition_item_histories (id, requisition_id, item, quantity_requested, quantity_ordered, quantity_delivered, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: requisition_item_lists; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.requisition_item_lists (id, requisition_id, item_id, quantity, notes, created_at, updated_at, item_type, account_code, ofm_list_id) FROM stdin;
\.


--
-- Data for Name: requisition_order_histories; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.requisition_order_histories (id, requisition_id, po_number, supplier, po_price, date_ordered, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: requisition_payment_histories; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.requisition_payment_histories (id, requisition_id, pr_number, amount, supplier, status, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: requisition_return_histories; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.requisition_return_histories (id, requisition_id, dr_number, item, supplier, status, quantity_ordered, quantity_returned, return_date, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: requisitions; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.requisitions (id, rs_number, company_code, rs_letter, created_by, company_id, department_id, project_id, date_required, delivery_address, purpose, charge_to, status, assigned_to, created_at, updated_at, type, draft_rs_number, charge_to_id, company_name, company_name_locked, category, "chargeToId", force_closed_at, force_closed_by, force_close_reason, force_close_scenario) FROM stdin;
\.


--
-- Data for Name: role_permissions; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.role_permissions (id, role_id, permission_id, created_at, updated_at) FROM stdin;
1	1	1	2025-06-29 23:46:33.609+00	2025-06-29 23:46:33.609+00
2	1	2	2025-06-29 23:46:33.609+00	2025-06-29 23:46:33.609+00
3	1	3	2025-06-29 23:46:33.609+00	2025-06-29 23:46:33.609+00
4	1	4	2025-06-29 23:46:33.609+00	2025-06-29 23:46:33.609+00
5	1	5	2025-06-29 23:46:33.609+00	2025-06-29 23:46:33.609+00
6	1	6	2025-06-29 23:46:33.609+00	2025-06-29 23:46:33.609+00
7	1	20	2025-06-29 23:46:33.609+00	2025-06-29 23:46:33.609+00
8	2	1	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
9	2	2	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
10	2	3	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
11	2	4	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
12	2	5	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
13	2	6	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
14	2	7	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
15	2	8	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
16	2	9	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
17	2	10	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
18	2	11	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
19	2	12	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
20	2	13	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
21	2	14	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
22	2	15	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
23	2	16	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
24	2	17	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
25	2	18	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
26	2	19	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
27	2	20	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
28	2	21	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
29	2	22	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
30	2	23	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
31	2	24	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
32	2	25	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
33	2	26	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
34	2	27	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
35	2	28	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
36	2	29	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
37	2	30	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
38	2	31	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
39	2	32	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
40	2	33	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
41	2	34	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
42	2	35	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
43	2	36	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
44	2	37	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
45	2	38	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
46	2	39	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
47	2	40	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
48	2	41	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
49	2	42	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
50	2	43	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
51	2	44	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
52	2	45	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
53	2	46	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
54	2	47	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
55	2	48	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
56	2	50	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
57	2	51	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
58	2	52	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
59	2	53	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
60	2	58	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
61	2	59	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
62	2	64	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
63	2	65	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
64	2	66	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
65	2	67	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
66	2	68	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
67	2	69	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
68	2	70	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
69	2	71	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
70	2	72	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
71	2	73	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
72	2	74	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
73	2	75	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
74	2	76	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
75	2	77	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
76	2	78	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
77	2	79	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
78	2	80	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
79	2	81	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
80	2	82	2025-06-29 23:46:33.627+00	2025-06-29 23:46:33.627+00
81	4	44	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
82	4	45	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
83	4	46	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
84	4	47	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
85	4	48	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
86	4	49	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
87	4	52	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
88	4	53	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
89	4	55	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
90	4	57	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
91	4	58	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
92	4	59	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
93	4	60	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
94	4	61	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
95	4	62	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
96	4	63	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
97	4	64	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
98	4	65	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
99	4	66	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
100	4	67	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
101	4	68	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
102	4	69	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
103	4	70	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
104	4	71	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
105	4	72	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
106	4	73	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
107	4	74	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
108	4	75	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
109	4	76	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
110	4	77	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
111	4	78	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
112	4	79	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
113	4	80	2025-06-29 23:46:33.653+00	2025-06-29 23:46:33.653+00
114	5	44	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
115	5	45	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
116	5	46	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
117	5	47	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
118	5	48	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
119	5	49	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
120	5	52	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
121	5	53	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
122	5	57	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
123	5	58	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
124	5	59	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
125	5	60	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
126	5	61	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
127	5	62	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
128	5	63	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
129	5	64	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
130	5	65	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
131	5	66	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
132	5	67	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
133	5	68	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
134	5	69	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
135	5	70	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
136	5	71	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
137	5	72	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
138	5	73	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
139	5	74	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
140	5	75	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
141	5	76	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
142	5	77	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
143	5	78	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
144	5	79	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
145	5	80	2025-06-29 23:46:33.677+00	2025-06-29 23:46:33.677+00
146	6	44	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
147	6	45	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
148	6	46	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
149	6	47	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
150	6	48	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
151	6	49	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
152	6	52	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
153	6	53	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
154	6	57	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
155	6	58	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
156	6	59	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
157	6	60	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
158	6	61	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
159	6	62	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
160	6	63	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
161	6	64	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
162	6	65	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
163	6	66	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
164	6	67	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
165	6	68	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
166	6	69	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
167	6	70	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
168	6	71	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
169	6	72	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
170	6	73	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
171	6	74	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
172	6	75	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
173	6	76	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
174	6	77	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
175	6	78	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
176	6	79	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
177	6	80	2025-06-29 23:46:33.694+00	2025-06-29 23:46:33.694+00
178	9	29	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
179	9	30	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
180	9	31	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
181	9	32	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
182	9	35	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
183	9	36	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
184	9	37	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
185	9	38	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
186	9	39	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
187	9	40	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
188	9	41	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
189	9	42	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
190	9	43	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
191	9	44	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
192	9	45	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
193	9	46	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
194	9	47	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
195	9	48	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
196	9	49	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
197	9	52	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
198	9	53	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
199	9	54	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
200	9	55	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
201	9	56	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
202	9	57	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
203	9	58	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
204	9	59	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
205	9	60	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
206	9	61	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
207	9	62	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
208	9	63	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
209	9	64	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
210	9	65	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
211	9	66	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
212	9	67	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
213	9	68	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
214	9	69	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
215	9	70	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
216	9	71	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
217	9	72	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
218	9	73	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
219	9	74	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
220	9	75	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
221	9	76	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
222	9	77	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
223	9	78	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
224	9	79	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
225	9	80	2025-06-29 23:46:33.711+00	2025-06-29 23:46:33.711+00
226	7	44	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
227	7	45	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
228	7	46	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
229	7	47	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
230	7	48	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
231	7	49	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
232	7	52	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
233	7	53	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
234	7	57	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
235	7	58	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
236	7	59	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
237	7	60	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
238	7	61	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
239	7	62	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
240	7	63	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
241	7	64	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
242	7	65	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
243	7	66	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
244	7	67	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
245	7	68	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
246	7	69	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
247	7	70	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
248	7	71	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
249	7	72	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
250	7	73	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
251	7	74	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
252	7	75	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
253	7	76	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
254	7	77	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
255	7	78	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
256	7	79	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
257	7	80	2025-06-29 23:46:33.759+00	2025-06-29 23:46:33.759+00
258	3	3	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
259	3	9	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
260	3	14	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
261	3	20	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
262	3	29	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
263	3	30	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
264	3	31	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
265	3	32	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
266	3	35	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
267	3	36	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
268	3	37	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
269	3	38	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
270	3	39	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
271	3	40	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
272	3	44	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
273	3	45	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
274	3	46	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
275	3	47	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
276	3	48	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
277	3	52	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
278	3	53	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
279	3	58	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
280	3	59	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
281	3	64	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
282	3	65	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
283	3	66	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
284	3	67	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
285	3	68	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
286	3	69	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
287	3	70	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
288	3	75	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
289	3	76	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
290	3	77	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
291	3	78	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
292	3	79	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
293	3	80	2025-06-29 23:46:33.788+00	2025-06-29 23:46:33.788+00
294	8	44	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
295	8	45	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
296	8	46	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
297	8	47	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
298	8	48	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
299	8	49	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
300	8	52	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
301	8	53	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
302	8	57	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
303	8	58	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
304	8	59	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
305	8	60	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
306	8	61	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
307	8	62	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
308	8	63	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
309	8	64	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
310	8	65	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
311	8	66	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
312	8	67	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
313	8	68	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
314	8	75	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
315	8	76	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
316	8	77	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
317	8	78	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
318	8	79	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
319	8	80	2025-06-29 23:46:33.807+00	2025-06-29 23:46:33.807+00
320	10	29	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
321	10	30	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
322	10	31	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
323	10	32	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
324	10	35	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
325	10	36	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
326	10	37	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
327	10	38	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
328	10	39	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
329	10	40	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
330	10	41	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
331	10	42	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
332	10	43	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
333	10	44	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
334	10	45	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
335	10	46	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
336	10	47	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
337	10	48	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
338	10	49	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
339	10	52	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
340	10	53	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
341	10	54	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
342	10	55	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
343	10	56	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
344	10	57	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
345	10	58	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
346	10	59	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
347	10	60	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
348	10	61	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
349	10	62	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
350	10	63	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
351	10	64	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
352	10	65	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
353	10	66	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
354	10	67	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
355	10	68	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
356	10	69	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
357	10	70	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
358	10	71	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
359	10	72	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
360	10	73	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
361	10	74	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
362	10	75	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
363	10	76	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
364	10	77	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
365	10	78	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
366	10	79	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
367	10	80	2025-06-29 23:46:33.822+00	2025-06-29 23:46:33.822+00
368	11	44	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
369	11	45	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
370	11	46	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
371	11	47	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
372	11	48	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
373	11	52	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
374	11	53	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
375	11	54	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
376	11	55	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
377	11	56	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
378	11	57	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
379	11	58	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
380	11	59	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
381	11	60	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
382	11	61	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
383	11	62	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
384	11	64	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
385	11	65	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
386	11	66	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
387	11	67	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
388	11	68	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
389	11	69	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
390	11	70	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
391	11	75	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
392	11	76	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
393	11	77	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
394	11	78	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
395	11	79	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
396	11	80	2025-06-29 23:46:33.847+00	2025-06-29 23:46:33.847+00
397	12	1	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
398	12	7	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
399	12	8	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
400	12	9	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
401	12	10	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
402	12	11	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
403	12	12	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
404	12	13	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
405	12	14	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
406	12	15	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
407	12	16	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
408	12	17	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
409	12	18	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
410	12	19	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
411	12	20	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
412	12	21	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
413	12	22	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
414	12	23	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
415	12	24	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
416	12	25	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
417	12	26	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
418	12	27	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
419	12	28	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
420	12	29	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
421	12	30	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
422	12	31	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
423	12	32	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
424	12	33	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
425	12	34	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
426	12	35	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
427	12	36	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
428	12	37	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
429	12	38	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
430	12	39	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
431	12	40	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
432	12	41	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
433	12	42	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
434	12	43	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
435	12	44	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
436	12	45	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
437	12	46	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
438	12	47	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
439	12	48	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
440	12	50	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
441	12	51	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
442	12	52	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
443	12	53	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
444	12	58	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
445	12	59	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
446	12	64	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
447	12	65	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
448	12	66	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
449	12	67	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
450	12	68	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
451	12	69	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
452	12	70	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
453	12	71	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
454	12	72	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
455	12	73	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
456	12	74	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
457	12	75	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
458	12	76	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
459	12	77	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
460	12	78	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
461	12	79	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
462	12	80	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
463	12	81	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
464	12	82	2025-06-29 23:46:33.876+00	2025-06-29 23:46:33.876+00
465	3	83	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
466	3	87	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
467	3	85	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
468	3	86	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
469	3	84	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
470	4	83	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
471	4	87	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
472	4	85	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
473	4	86	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
474	4	84	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
475	5	83	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
476	5	87	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
477	5	85	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
478	5	86	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
479	5	84	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
480	6	83	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
481	6	87	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
482	6	85	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
483	6	86	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
484	6	84	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
485	7	83	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
486	7	87	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
487	7	85	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
488	7	86	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
489	7	84	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
490	8	83	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
491	8	87	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
492	8	85	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
493	8	86	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
494	8	84	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
495	9	83	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
496	9	87	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
497	9	85	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
498	9	86	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
499	9	84	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
500	10	83	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
501	10	87	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
502	10	85	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
503	10	86	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
504	10	84	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
505	11	83	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
506	11	87	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
507	11	85	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
508	11	86	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
509	11	84	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
510	12	83	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
511	12	87	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
512	12	85	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
513	12	86	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
514	12	84	2025-06-29 23:46:33.895+00	2025-06-29 23:46:33.895+00
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.roles (id, name, is_permanent, created_at, updated_at) FROM stdin;
1	Root User	t	2025-06-29 23:46:33.354+00	2025-06-29 23:46:33.354+00
2	Admin	t	2025-06-29 23:46:33.354+00	2025-06-29 23:46:33.354+00
3	Engineers	t	2025-06-29 23:46:33.354+00	2025-06-29 23:46:33.354+00
4	Supervisor	t	2025-06-29 23:46:33.354+00	2025-06-29 23:46:33.354+00
5	Assistant Manager	t	2025-06-29 23:46:33.354+00	2025-06-29 23:46:33.354+00
6	Department Head	t	2025-06-29 23:46:33.354+00	2025-06-29 23:46:33.354+00
7	Division Head	t	2025-06-29 23:46:33.354+00	2025-06-29 23:46:33.354+00
8	Area Staff/Department Secretary	t	2025-06-29 23:46:33.354+00	2025-06-29 23:46:33.354+00
9	Purchasing Staff	t	2025-06-29 23:46:33.354+00	2025-06-29 23:46:33.354+00
10	Purchasing Head	t	2025-06-29 23:46:33.354+00	2025-06-29 23:46:33.354+00
11	Management	t	2025-06-29 23:46:33.354+00	2025-06-29 23:46:33.354+00
12	Purchasing Admin	t	2025-06-29 23:46:33.354+00	2025-06-29 23:46:33.354+00
\.


--
-- Data for Name: rs_payment_request_approvers; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.rs_payment_request_approvers (id, payment_request_id, level, user_id, alt_approver_id, status, role_id, is_adhoc, created_at, updated_at, override_by) FROM stdin;
\.


--
-- Data for Name: rs_payment_requests; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.rs_payment_requests (id, draft_pr_number, pr_number, pr_letter, is_draft, requisition_id, purchase_order_id, delivery_invoice_id, terms_data, payable_date, discount_in, discount_percentage, discount_amount, withholding_tax_deduction, delivery_fee, tip, extra_charges, status, total_amount, created_at, updated_at, last_approver_id, cancelled_at, cancelled_by, cancellation_reason) FROM stdin;
\.


--
-- Data for Name: steelbars; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.steelbars (id, grade, diameter, length, weight, kg_per_meter, ofm_acctcd, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: suppliers; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.suppliers (id, user_id, name, contact, tin, address, contact_person, contact_number, citizenship_code, nature_of_income, pay_code, ic_code, status, deleted_at, created_at, updated_at, line_of_business) FROM stdin;
\.


--
-- Data for Name: syncs; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.syncs (id, model, last_synced_at) FROM stdin;
\.


--
-- Data for Name: timescaledb_migration_status; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.timescaledb_migration_status (id, table_name, is_hypertable_ready, constraint_migration_needed, compression_enabled, chunk_time_interval, compression_after, notes, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: tom_items; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.tom_items (id, name, unit, quantity, comment, requisition_id, created_at, updated_at, notes) FROM stdin;
\.


--
-- Data for Name: trades; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.trades (id, trade_code, created_at, updated_at, category, trade_name) FROM stdin;
1	11	2025-06-29 23:46:33.73+00	2025-06-29 23:46:33.73+00	MAJOR	Civil and Architecture Works
2	12	2025-06-29 23:46:33.73+00	2025-06-29 23:46:33.73+00	MAJOR	Mechanical Works
3	13	2025-06-29 23:46:33.73+00	2025-06-29 23:46:33.73+00	MAJOR	Electrical Works
4	14	2025-06-29 23:46:33.73+00	2025-06-29 23:46:33.73+00	MAJOR	Plumbing and Sanitary Works
5	15	2025-06-29 23:46:33.73+00	2025-06-29 23:46:33.73+00	MAJOR	Fire Protection Works
6	16	2025-06-29 23:46:33.73+00	2025-06-29 23:46:33.73+00	SUB	Bored Piles Work
7	17	2025-06-29 23:46:33.73+00	2025-06-29 23:46:33.73+00	SUB	Substructure Works
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.users (id, username, email, password, first_name, last_name, role_id, otp_secret, status, is_password_temporary, created_at, updated_at, deleted_at, department_id, temp_pass, supervisor_id) FROM stdin;
1	admin	admin@admin.com	$2a$10$IPHHT4dYCiVhkDxdfV7eVOaQCFQ7.52.B1qpcfcnNoYV3fXVuxBiO	Root	User	1	\N	active	f	2025-06-29 23:46:33.538+00	2025-06-29 23:46:33.538+00	\N	\N	\N	\N
\.


--
-- Data for Name: warranties; Type: TABLE DATA; Schema: public; Owner: prs_user
--

COPY public.warranties (id, name, type, created_at, updated_at) FROM stdin;
1	7 Days	purchase_order	2025-06-29 23:46:33.867324+00	2025-06-29 23:46:33.867324+00
2	30 Days	purchase_order	2025-06-29 23:46:33.867324+00	2025-06-29 23:46:33.867324+00
3	1 Month	purchase_order	2025-06-29 23:46:33.867324+00	2025-06-29 23:46:33.867324+00
4	3 Months	purchase_order	2025-06-29 23:46:33.867324+00	2025-06-29 23:46:33.867324+00
5	6 Months	purchase_order	2025-06-29 23:46:33.867324+00	2025-06-29 23:46:33.867324+00
6	1 Year	purchase_order	2025-06-29 23:46:33.867324+00	2025-06-29 23:46:33.867324+00
\.


--
-- Name: chunk_column_stats_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: prs_user
--

SELECT pg_catalog.setval('_timescaledb_catalog.chunk_column_stats_id_seq', 1, false);


--
-- Name: chunk_constraint_name; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: prs_user
--

SELECT pg_catalog.setval('_timescaledb_catalog.chunk_constraint_name', 1, false);


--
-- Name: chunk_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: prs_user
--

SELECT pg_catalog.setval('_timescaledb_catalog.chunk_id_seq', 1, false);


--
-- Name: continuous_agg_migrate_plan_step_step_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: prs_user
--

SELECT pg_catalog.setval('_timescaledb_catalog.continuous_agg_migrate_plan_step_step_id_seq', 1, false);


--
-- Name: dimension_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: prs_user
--

SELECT pg_catalog.setval('_timescaledb_catalog.dimension_id_seq', 37, true);


--
-- Name: dimension_slice_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: prs_user
--

SELECT pg_catalog.setval('_timescaledb_catalog.dimension_slice_id_seq', 1, false);


--
-- Name: hypertable_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_catalog; Owner: prs_user
--

SELECT pg_catalog.setval('_timescaledb_catalog.hypertable_id_seq', 73, true);


--
-- Name: bgw_job_id_seq; Type: SEQUENCE SET; Schema: _timescaledb_config; Owner: prs_user
--

SELECT pg_catalog.setval('_timescaledb_config.bgw_job_id_seq', 1035, true);


--
-- Name: approval_types_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.approval_types_id_seq', 4, true);


--
-- Name: association_areas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.association_areas_id_seq', 1, false);


--
-- Name: attachment_badges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.attachment_badges_id_seq', 1, false);


--
-- Name: attachments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.attachments_id_seq', 1, false);


--
-- Name: audit_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.audit_logs_id_seq', 1, false);


--
-- Name: canvass_approvers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.canvass_approvers_id_seq', 1, false);


--
-- Name: canvass_item_suppliers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.canvass_item_suppliers_id_seq', 1, false);


--
-- Name: canvass_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.canvass_items_id_seq', 1, false);


--
-- Name: canvass_requisitions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.canvass_requisitions_id_seq', 1, false);


--
-- Name: comment_badges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.comment_badges_id_seq', 1, false);


--
-- Name: comments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.comments_id_seq', 1, false);


--
-- Name: companies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.companies_id_seq', 1, false);


--
-- Name: delivery_receipt_invoices_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.delivery_receipt_invoices_id_seq', 1, false);


--
-- Name: delivery_receipt_items_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.delivery_receipt_items_history_id_seq', 1, false);


--
-- Name: delivery_receipt_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.delivery_receipt_items_id_seq', 1, false);


--
-- Name: delivery_receipts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.delivery_receipts_id_seq', 1, false);


--
-- Name: department_approvals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.department_approvals_id_seq', 1, false);


--
-- Name: department_association_approvals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.department_association_approvals_id_seq', 1, false);


--
-- Name: departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.departments_id_seq', 1, false);


--
-- Name: force_close_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.force_close_logs_id_seq', 1, false);


--
-- Name: gate_passes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.gate_passes_id_seq', 1, false);


--
-- Name: histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.histories_id_seq', 1, false);


--
-- Name: invoice_report_histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.invoice_report_histories_id_seq', 1, false);


--
-- Name: invoice_reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.invoice_reports_id_seq', 1, false);


--
-- Name: items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.items_id_seq', 1, false);


--
-- Name: leaves_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.leaves_id_seq', 1, false);


--
-- Name: non_ofm_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.non_ofm_items_id_seq', 1, false);


--
-- Name: non_requisition_approvers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.non_requisition_approvers_id_seq', 1, false);


--
-- Name: non_requisition_histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.non_requisition_histories_id_seq', 1, false);


--
-- Name: non_requisition_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.non_requisition_items_id_seq', 1, false);


--
-- Name: non_requisitions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.non_requisitions_id_seq', 1, false);


--
-- Name: note_badges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.note_badges_id_seq', 1, false);


--
-- Name: notes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.notes_id_seq', 1, false);


--
-- Name: notifications_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.notifications_id_seq', 1, false);


--
-- Name: ofm_item_lists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.ofm_item_lists_id_seq', 1, false);


--
-- Name: ofm_list_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.ofm_list_items_id_seq', 1, false);


--
-- Name: permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.permissions_id_seq', 87, true);


--
-- Name: project_approvals_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.project_approvals_id_seq', 1, false);


--
-- Name: project_companies_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.project_companies_id_seq', 1, false);


--
-- Name: projects_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.projects_id_seq', 1, false);


--
-- Name: projects_trades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.projects_trades_id_seq', 1, false);


--
-- Name: prs_timescaledb_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.prs_timescaledb_status_id_seq', 1, false);


--
-- Name: purchase_order_approvers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.purchase_order_approvers_id_seq', 1, false);


--
-- Name: purchase_order_cancelled_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.purchase_order_cancelled_items_id_seq', 1, false);


--
-- Name: purchase_order_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.purchase_order_items_id_seq', 1, false);


--
-- Name: purchase_orders_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.purchase_orders_id_seq', 1, false);


--
-- Name: requisition_approvers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.requisition_approvers_id_seq', 1, false);


--
-- Name: requisition_badges_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.requisition_badges_id_seq', 1, false);


--
-- Name: requisition_canvass_histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.requisition_canvass_histories_id_seq', 1, false);


--
-- Name: requisition_delivery_histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.requisition_delivery_histories_id_seq', 1, false);


--
-- Name: requisition_item_histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.requisition_item_histories_id_seq', 1, false);


--
-- Name: requisition_item_lists_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.requisition_item_lists_id_seq', 1, false);


--
-- Name: requisition_order_histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.requisition_order_histories_id_seq', 1, false);


--
-- Name: requisition_payment_histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.requisition_payment_histories_id_seq', 1, false);


--
-- Name: requisition_return_histories_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.requisition_return_histories_id_seq', 1, false);


--
-- Name: requisitions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.requisitions_id_seq', 1, false);


--
-- Name: role_permissions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.role_permissions_id_seq', 514, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.roles_id_seq', 12, true);


--
-- Name: rs_payment_request_approvers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.rs_payment_request_approvers_id_seq', 1, false);


--
-- Name: rs_payment_requests_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.rs_payment_requests_id_seq', 1, false);


--
-- Name: steelbars_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.steelbars_id_seq', 1, false);


--
-- Name: suppliers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.suppliers_id_seq', 1, false);


--
-- Name: syncs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.syncs_id_seq', 1, false);


--
-- Name: timescaledb_migration_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.timescaledb_migration_status_id_seq', 1, false);


--
-- Name: tom_items_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.tom_items_id_seq', 1, false);


--
-- Name: trades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.trades_id_seq', 7, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.users_id_seq', 2, true);


--
-- Name: warranties_id_seq; Type: SEQUENCE SET; Schema: public; Owner: prs_user
--

SELECT pg_catalog.setval('public.warranties_id_seq', 6, true);


--
-- Name: SequelizeMeta SequelizeMeta_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public."SequelizeMeta"
    ADD CONSTRAINT "SequelizeMeta_pkey" PRIMARY KEY (name);


--
-- Name: approval_types approval_types_code_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.approval_types
    ADD CONSTRAINT approval_types_code_key UNIQUE (code);


--
-- Name: approval_types approval_types_name_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.approval_types
    ADD CONSTRAINT approval_types_name_key UNIQUE (name);


--
-- Name: approval_types approval_types_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.approval_types
    ADD CONSTRAINT approval_types_pkey PRIMARY KEY (id);


--
-- Name: association_areas association_areas_code_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.association_areas
    ADD CONSTRAINT association_areas_code_key UNIQUE (code);


--
-- Name: association_areas association_areas_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.association_areas
    ADD CONSTRAINT association_areas_pkey PRIMARY KEY (id);


--
-- Name: attachment_badges attachment_badges_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.attachment_badges
    ADD CONSTRAINT attachment_badges_pkey PRIMARY KEY (id);


--
-- Name: attachments attachments_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.attachments
    ADD CONSTRAINT attachments_pkey PRIMARY KEY (id, created_at);


--
-- Name: audit_logs audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.audit_logs
    ADD CONSTRAINT audit_logs_pkey PRIMARY KEY (id, created_at);


--
-- Name: canvass_approvers canvass_approvers_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.canvass_approvers
    ADD CONSTRAINT canvass_approvers_pkey PRIMARY KEY (id, created_at);


--
-- Name: canvass_item_suppliers canvass_item_suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.canvass_item_suppliers
    ADD CONSTRAINT canvass_item_suppliers_pkey PRIMARY KEY (id, created_at);


--
-- Name: canvass_items canvass_items_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.canvass_items
    ADD CONSTRAINT canvass_items_pkey PRIMARY KEY (id, created_at);


--
-- Name: canvass_requisitions canvass_requisitions_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.canvass_requisitions
    ADD CONSTRAINT canvass_requisitions_pkey PRIMARY KEY (id, created_at);


--
-- Name: comment_badges comment_badges_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.comment_badges
    ADD CONSTRAINT comment_badges_pkey PRIMARY KEY (id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id, created_at);


--
-- Name: companies companies_code_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_code_key UNIQUE (code);


--
-- Name: companies companies_code_key1; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_code_key1 UNIQUE (code);


--
-- Name: companies companies_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.companies
    ADD CONSTRAINT companies_pkey PRIMARY KEY (id);


--
-- Name: delivery_receipt_invoices delivery_receipt_invoices_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.delivery_receipt_invoices
    ADD CONSTRAINT delivery_receipt_invoices_pkey PRIMARY KEY (id, created_at);


--
-- Name: delivery_receipt_items_history delivery_receipt_items_history_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.delivery_receipt_items_history
    ADD CONSTRAINT delivery_receipt_items_history_pkey PRIMARY KEY (id, created_at);


--
-- Name: delivery_receipt_items delivery_receipt_items_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.delivery_receipt_items
    ADD CONSTRAINT delivery_receipt_items_pkey PRIMARY KEY (id, created_at);


--
-- Name: delivery_receipts delivery_receipts_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.delivery_receipts
    ADD CONSTRAINT delivery_receipts_pkey PRIMARY KEY (id, created_at);


--
-- Name: department_approvals department_approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.department_approvals
    ADD CONSTRAINT department_approvals_pkey PRIMARY KEY (id);


--
-- Name: department_association_approvals department_association_approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.department_association_approvals
    ADD CONSTRAINT department_association_approvals_pkey PRIMARY KEY (id);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: force_close_logs force_close_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.force_close_logs
    ADD CONSTRAINT force_close_logs_pkey PRIMARY KEY (id, created_at);


--
-- Name: gate_passes gate_passes_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.gate_passes
    ADD CONSTRAINT gate_passes_pkey PRIMARY KEY (id);


--
-- Name: histories histories_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.histories
    ADD CONSTRAINT histories_pkey PRIMARY KEY (id, created_at);


--
-- Name: invoice_report_histories invoice_report_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.invoice_report_histories
    ADD CONSTRAINT invoice_report_histories_pkey PRIMARY KEY (id, created_at);


--
-- Name: invoice_reports invoice_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.invoice_reports
    ADD CONSTRAINT invoice_reports_pkey PRIMARY KEY (id, created_at);


--
-- Name: items items_item_cd_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_item_cd_key UNIQUE (item_cd);


--
-- Name: items items_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.items
    ADD CONSTRAINT items_pkey PRIMARY KEY (id);


--
-- Name: leaves leaves_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.leaves
    ADD CONSTRAINT leaves_pkey PRIMARY KEY (id);


--
-- Name: non_ofm_items non_ofm_items_acct_cd_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.non_ofm_items
    ADD CONSTRAINT non_ofm_items_acct_cd_key UNIQUE (acct_cd);


--
-- Name: non_ofm_items non_ofm_items_item_name_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.non_ofm_items
    ADD CONSTRAINT non_ofm_items_item_name_key UNIQUE (item_name);


--
-- Name: non_ofm_items non_ofm_items_item_name_key1; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.non_ofm_items
    ADD CONSTRAINT non_ofm_items_item_name_key1 UNIQUE (item_name);


--
-- Name: non_ofm_items non_ofm_items_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.non_ofm_items
    ADD CONSTRAINT non_ofm_items_pkey PRIMARY KEY (id);


--
-- Name: non_requisition_approvers non_requisition_approvers_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.non_requisition_approvers
    ADD CONSTRAINT non_requisition_approvers_pkey PRIMARY KEY (id, created_at);


--
-- Name: non_requisition_histories non_requisition_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.non_requisition_histories
    ADD CONSTRAINT non_requisition_histories_pkey PRIMARY KEY (id, created_at);


--
-- Name: non_requisition_items non_requisition_items_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.non_requisition_items
    ADD CONSTRAINT non_requisition_items_pkey PRIMARY KEY (id, created_at);


--
-- Name: non_requisitions non_requisitions_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.non_requisitions
    ADD CONSTRAINT non_requisitions_pkey PRIMARY KEY (id, created_at);


--
-- Name: note_badges note_badges_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.note_badges
    ADD CONSTRAINT note_badges_pkey PRIMARY KEY (id);


--
-- Name: notes notes_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.notes
    ADD CONSTRAINT notes_pkey PRIMARY KEY (id, created_at);


--
-- Name: notifications notifications_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.notifications
    ADD CONSTRAINT notifications_pkey PRIMARY KEY (id, created_at);


--
-- Name: ofm_item_lists ofm_item_lists_list_name_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.ofm_item_lists
    ADD CONSTRAINT ofm_item_lists_list_name_key UNIQUE (list_name);


--
-- Name: ofm_item_lists ofm_item_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.ofm_item_lists
    ADD CONSTRAINT ofm_item_lists_pkey PRIMARY KEY (id);


--
-- Name: ofm_list_items ofm_list_items_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.ofm_list_items
    ADD CONSTRAINT ofm_list_items_pkey PRIMARY KEY (id);


--
-- Name: permissions permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.permissions
    ADD CONSTRAINT permissions_pkey PRIMARY KEY (id);


--
-- Name: project_approvals project_approvals_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.project_approvals
    ADD CONSTRAINT project_approvals_pkey PRIMARY KEY (id);


--
-- Name: project_companies project_companies_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.project_companies
    ADD CONSTRAINT project_companies_pkey PRIMARY KEY (id);


--
-- Name: projects projects_code_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_code_key UNIQUE (code);


--
-- Name: projects projects_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.projects
    ADD CONSTRAINT projects_pkey PRIMARY KEY (id);


--
-- Name: projects_trades projects_trades_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.projects_trades
    ADD CONSTRAINT projects_trades_pkey PRIMARY KEY (id);


--
-- Name: prs_timescaledb_status prs_timescaledb_status_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.prs_timescaledb_status
    ADD CONSTRAINT prs_timescaledb_status_pkey PRIMARY KEY (id);


--
-- Name: prs_timescaledb_status prs_timescaledb_status_table_name_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.prs_timescaledb_status
    ADD CONSTRAINT prs_timescaledb_status_table_name_key UNIQUE (table_name);


--
-- Name: purchase_order_approvers purchase_order_approvers_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.purchase_order_approvers
    ADD CONSTRAINT purchase_order_approvers_pkey PRIMARY KEY (id, created_at);


--
-- Name: purchase_order_cancelled_items purchase_order_cancelled_items_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.purchase_order_cancelled_items
    ADD CONSTRAINT purchase_order_cancelled_items_pkey PRIMARY KEY (id, created_at);


--
-- Name: purchase_order_items purchase_order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.purchase_order_items
    ADD CONSTRAINT purchase_order_items_pkey PRIMARY KEY (id, created_at);


--
-- Name: purchase_orders purchase_orders_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.purchase_orders
    ADD CONSTRAINT purchase_orders_pkey PRIMARY KEY (id, created_at);


--
-- Name: requisition_approvers requisition_approvers_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_approvers
    ADD CONSTRAINT requisition_approvers_pkey PRIMARY KEY (id, created_at);


--
-- Name: requisition_badges requisition_badges_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_badges
    ADD CONSTRAINT requisition_badges_pkey PRIMARY KEY (id, created_at);


--
-- Name: requisition_canvass_histories requisition_canvass_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_canvass_histories
    ADD CONSTRAINT requisition_canvass_histories_pkey PRIMARY KEY (id, created_at);


--
-- Name: requisition_delivery_histories requisition_delivery_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_delivery_histories
    ADD CONSTRAINT requisition_delivery_histories_pkey PRIMARY KEY (id, created_at);


--
-- Name: requisition_item_histories requisition_item_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_item_histories
    ADD CONSTRAINT requisition_item_histories_pkey PRIMARY KEY (id, created_at);


--
-- Name: requisition_item_lists requisition_item_lists_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_item_lists
    ADD CONSTRAINT requisition_item_lists_pkey PRIMARY KEY (id, created_at);


--
-- Name: requisition_order_histories requisition_order_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_order_histories
    ADD CONSTRAINT requisition_order_histories_pkey PRIMARY KEY (id, created_at);


--
-- Name: requisition_payment_histories requisition_payment_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_payment_histories
    ADD CONSTRAINT requisition_payment_histories_pkey PRIMARY KEY (id, created_at);


--
-- Name: requisition_return_histories requisition_return_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisition_return_histories
    ADD CONSTRAINT requisition_return_histories_pkey PRIMARY KEY (id, created_at);


--
-- Name: requisitions requisitions_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.requisitions
    ADD CONSTRAINT requisitions_pkey PRIMARY KEY (id, created_at);


--
-- Name: role_permissions role_permissions_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_pkey PRIMARY KEY (id);


--
-- Name: roles roles_name_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_name_key UNIQUE (name);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: rs_payment_request_approvers rs_payment_request_approvers_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.rs_payment_request_approvers
    ADD CONSTRAINT rs_payment_request_approvers_pkey PRIMARY KEY (id, created_at);


--
-- Name: rs_payment_requests rs_payment_requests_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.rs_payment_requests
    ADD CONSTRAINT rs_payment_requests_pkey PRIMARY KEY (id, created_at);


--
-- Name: steelbars steelbars_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.steelbars
    ADD CONSTRAINT steelbars_pkey PRIMARY KEY (id);


--
-- Name: suppliers suppliers_pay_code_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pay_code_key UNIQUE (pay_code);


--
-- Name: suppliers suppliers_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_pkey PRIMARY KEY (id);


--
-- Name: syncs syncs_model_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.syncs
    ADD CONSTRAINT syncs_model_key UNIQUE (model);


--
-- Name: syncs syncs_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.syncs
    ADD CONSTRAINT syncs_pkey PRIMARY KEY (id);


--
-- Name: timescaledb_migration_status timescaledb_migration_status_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.timescaledb_migration_status
    ADD CONSTRAINT timescaledb_migration_status_pkey PRIMARY KEY (id);


--
-- Name: timescaledb_migration_status timescaledb_migration_status_table_name_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.timescaledb_migration_status
    ADD CONSTRAINT timescaledb_migration_status_table_name_key UNIQUE (table_name);


--
-- Name: tom_items tom_items_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.tom_items
    ADD CONSTRAINT tom_items_pkey PRIMARY KEY (id);


--
-- Name: trades trades_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.trades
    ADD CONSTRAINT trades_pkey PRIMARY KEY (id);


--
-- Name: trades trades_trade_code_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.trades
    ADD CONSTRAINT trades_trade_code_key UNIQUE (trade_code);


--
-- Name: departments unique_department_code_per_department; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT unique_department_code_per_department UNIQUE (code);


--
-- Name: steelbars unique_grade_diameter_length_ofm_acctcd; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.steelbars
    ADD CONSTRAINT unique_grade_diameter_length_ofm_acctcd UNIQUE (grade, diameter, length, ofm_acctcd);


--
-- Name: attachment_badges unique_user_attachment_constraint; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.attachment_badges
    ADD CONSTRAINT unique_user_attachment_constraint UNIQUE (user_id, attachment_id);


--
-- Name: comment_badges unique_user_comment_constraint; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.comment_badges
    ADD CONSTRAINT unique_user_comment_constraint UNIQUE (user_id, comment_id);


--
-- Name: note_badges unique_user_note_constraint; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.note_badges
    ADD CONSTRAINT unique_user_note_constraint UNIQUE (user_id, note_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_email_key1; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key1 UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: warranties warranties_pkey; Type: CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.warranties
    ADD CONSTRAINT warranties_pkey PRIMARY KEY (id);


--
-- Name: approval_types_code; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX approval_types_code ON public.approval_types USING btree (code);


--
-- Name: association_areas_code_unique; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE UNIQUE INDEX association_areas_code_unique ON public.association_areas USING btree (code);


--
-- Name: attachment_badges_user_id_attachment_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX attachment_badges_user_id_attachment_id ON public.attachment_badges USING btree (user_id, attachment_id);


--
-- Name: attachments_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX attachments_created_at_idx ON public.attachments USING btree (created_at DESC);


--
-- Name: attachments_model_model_id_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX attachments_model_model_id_index ON public.attachments USING btree (model, model_id);


--
-- Name: audit_logs_action_type; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX audit_logs_action_type ON public.audit_logs USING btree (action_type);


--
-- Name: audit_logs_created_at; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX audit_logs_created_at ON public.audit_logs USING btree (created_at);


--
-- Name: audit_logs_module; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX audit_logs_module ON public.audit_logs USING btree (module);


--
-- Name: canvass_approver; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_approver ON public.canvass_approvers USING btree (canvass_requisition_id, user_id) WHERE (user_id IS NOT NULL);


--
-- Name: canvass_approvers_canvass_requisition_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_approvers_canvass_requisition_id ON public.canvass_approvers USING btree (canvass_requisition_id);


--
-- Name: canvass_approvers_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_approvers_created_at_idx ON public.canvass_approvers USING btree (created_at DESC);


--
-- Name: canvass_approvers_level; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_approvers_level ON public.canvass_approvers USING btree (level);


--
-- Name: canvass_approvers_role_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_approvers_role_id ON public.canvass_approvers USING btree (role_id);


--
-- Name: canvass_approvers_user_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_approvers_user_id ON public.canvass_approvers USING btree (user_id);


--
-- Name: canvass_item_suppliers_canvass_item_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_item_suppliers_canvass_item_id ON public.canvass_item_suppliers USING btree (canvass_item_id);


--
-- Name: canvass_item_suppliers_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_item_suppliers_created_at_idx ON public.canvass_item_suppliers USING btree (created_at DESC);


--
-- Name: canvass_item_suppliers_order; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_item_suppliers_order ON public.canvass_item_suppliers USING btree ("order");


--
-- Name: canvass_item_suppliers_supplier_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_item_suppliers_supplier_id ON public.canvass_item_suppliers USING btree (supplier_id);


--
-- Name: canvass_items_canvass_requisition_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_items_canvass_requisition_id ON public.canvass_items USING btree (canvass_requisition_id);


--
-- Name: canvass_items_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_items_created_at_idx ON public.canvass_items USING btree (created_at DESC);


--
-- Name: canvass_items_requisition_item_list_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_items_requisition_item_list_id ON public.canvass_items USING btree (requisition_item_list_id);


--
-- Name: canvass_requisitions_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_requisitions_created_at_idx ON public.canvass_requisitions USING btree (created_at DESC);


--
-- Name: canvass_requisitions_requisition_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_requisitions_requisition_id ON public.canvass_requisitions USING btree (requisition_id);


--
-- Name: canvass_requisitions_status; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX canvass_requisitions_status ON public.canvass_requisitions USING btree (status);


--
-- Name: comment_badges_user_id_comment_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX comment_badges_user_id_comment_id ON public.comment_badges USING btree (user_id, comment_id);


--
-- Name: comments_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX comments_created_at_idx ON public.comments USING btree (created_at DESC);


--
-- Name: delivery_receipt_invoices_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX delivery_receipt_invoices_created_at_idx ON public.delivery_receipt_invoices USING btree (created_at DESC);


--
-- Name: delivery_receipt_items_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX delivery_receipt_items_created_at_idx ON public.delivery_receipt_items USING btree (created_at DESC);


--
-- Name: delivery_receipt_items_history_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX delivery_receipt_items_history_created_at_idx ON public.delivery_receipt_items_history USING btree (created_at DESC);


--
-- Name: delivery_receipts_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX delivery_receipts_created_at_idx ON public.delivery_receipts USING btree (created_at DESC);


--
-- Name: delivery_receipts_req_id_delivery_status_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX delivery_receipts_req_id_delivery_status_index ON public.delivery_receipts USING btree (requisition_id, latest_delivery_status);


--
-- Name: department_approvals_dept_type_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX department_approvals_dept_type_idx ON public.department_approvals USING btree (department_id, approval_type_code);


--
-- Name: department_association_approvals_approval_type_code; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX department_association_approvals_approval_type_code ON public.department_association_approvals USING btree (approval_type_code);


--
-- Name: department_association_approvals_approver_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX department_association_approvals_approver_id ON public.department_association_approvals USING btree (approver_id);


--
-- Name: department_association_approvals_area_code; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX department_association_approvals_area_code ON public.department_association_approvals USING btree (area_code);


--
-- Name: department_association_approvals_level; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX department_association_approvals_level ON public.department_association_approvals USING btree (level);


--
-- Name: departments_name; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX departments_name ON public.departments USING btree (name);


--
-- Name: draft_requisition_number_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX draft_requisition_number_index ON public.requisitions USING btree (company_code, rs_letter, draft_rs_number);


--
-- Name: histories_company_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX histories_company_id ON public.histories USING btree (company_id);


--
-- Name: histories_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX histories_created_at_idx ON public.histories USING btree (created_at DESC);


--
-- Name: histories_department_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX histories_department_id ON public.histories USING btree (department_id);


--
-- Name: histories_item_id_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX histories_item_id_idx ON public.histories USING btree (item_id);


--
-- Name: histories_item_id_type_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX histories_item_id_type_index ON public.histories USING btree (item_id, type);


--
-- Name: histories_project_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX histories_project_id ON public.histories USING btree (project_id);


--
-- Name: histories_rs_letter_rs_number_company_id_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX histories_rs_letter_rs_number_company_id_index ON public.histories USING btree (rs_letter, rs_number, company_id);


--
-- Name: idx_canvass_items_req_id_status; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_canvass_items_req_id_status ON public.canvass_items USING btree (requisition_id, status);


--
-- Name: idx_canvass_items_requisition_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_canvass_items_requisition_id ON public.canvass_items USING btree (requisition_id);


--
-- Name: idx_canvass_requisitions_cancelled_at; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_canvass_requisitions_cancelled_at ON public.canvass_requisitions USING btree (cancelled_at);


--
-- Name: idx_canvass_requisitions_cancelled_by; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_canvass_requisitions_cancelled_by ON public.canvass_requisitions USING btree (cancelled_by);


--
-- Name: idx_delivery_receipts_cancelled_at; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_delivery_receipts_cancelled_at ON public.delivery_receipts USING btree (cancelled_at);


--
-- Name: idx_delivery_receipts_cancelled_by; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_delivery_receipts_cancelled_by ON public.delivery_receipts USING btree (cancelled_by);


--
-- Name: idx_force_close_logs_created_at; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_force_close_logs_created_at ON public.force_close_logs USING btree (created_at);


--
-- Name: idx_force_close_logs_requisition_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_force_close_logs_requisition_id ON public.force_close_logs USING btree (requisition_id);


--
-- Name: idx_force_close_logs_scenario_type; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_force_close_logs_scenario_type ON public.force_close_logs USING btree (scenario_type);


--
-- Name: idx_force_close_logs_user_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_force_close_logs_user_id ON public.force_close_logs USING btree (user_id);


--
-- Name: idx_invoice_reports_cancelled_at; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_invoice_reports_cancelled_at ON public.invoice_reports USING btree (cancelled_at);


--
-- Name: idx_invoice_reports_cancelled_by; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_invoice_reports_cancelled_by ON public.invoice_reports USING btree (cancelled_by);


--
-- Name: idx_projects_trades_project_trade; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_projects_trades_project_trade ON public.projects_trades USING btree (project_id, trade_id);


--
-- Name: idx_requisitions_force_close_scenario; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_requisitions_force_close_scenario ON public.requisitions USING btree (force_close_scenario);


--
-- Name: idx_requisitions_force_closed_at; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_requisitions_force_closed_at ON public.requisitions USING btree (force_closed_at);


--
-- Name: idx_requisitions_force_closed_by; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_requisitions_force_closed_by ON public.requisitions USING btree (force_closed_by);


--
-- Name: idx_rs_payment_requests_cancelled_at; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_rs_payment_requests_cancelled_at ON public.rs_payment_requests USING btree (cancelled_at);


--
-- Name: idx_rs_payment_requests_cancelled_by; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX idx_rs_payment_requests_cancelled_by ON public.rs_payment_requests USING btree (cancelled_by);


--
-- Name: invoice_report_histories_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX invoice_report_histories_created_at_idx ON public.invoice_report_histories USING btree (created_at DESC);


--
-- Name: invoice_reports_company_code_ir_draft_number_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX invoice_reports_company_code_ir_draft_number_idx ON public.invoice_reports USING btree (company_code, ir_draft_number);


--
-- Name: invoice_reports_company_code_ir_number_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX invoice_reports_company_code_ir_number_idx ON public.invoice_reports USING btree (company_code, ir_number);


--
-- Name: invoice_reports_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX invoice_reports_created_at_idx ON public.invoice_reports USING btree (created_at DESC);


--
-- Name: non_requisition_approvers_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisition_approvers_created_at_idx ON public.non_requisition_approvers USING btree (created_at DESC);


--
-- Name: non_requisition_approvers_non_requisition_id_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisition_approvers_non_requisition_id_index ON public.non_requisition_approvers USING btree (non_requisition_id);


--
-- Name: non_requisition_approvers_role_id_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisition_approvers_role_id_index ON public.non_requisition_approvers USING btree (role_id);


--
-- Name: non_requisition_approvers_status_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisition_approvers_status_index ON public.non_requisition_approvers USING btree (status);


--
-- Name: non_requisition_approvers_user_id_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisition_approvers_user_id_index ON public.non_requisition_approvers USING btree (user_id);


--
-- Name: non_requisition_histories_approver_id_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisition_histories_approver_id_index ON public.non_requisition_histories USING btree (approver_id);


--
-- Name: non_requisition_histories_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisition_histories_created_at_idx ON public.non_requisition_histories USING btree (created_at DESC);


--
-- Name: non_requisition_histories_non_requisition_id_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisition_histories_non_requisition_id_index ON public.non_requisition_histories USING btree (non_requisition_id);


--
-- Name: non_requisition_histories_status_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisition_histories_status_index ON public.non_requisition_histories USING btree (status);


--
-- Name: non_requisition_histories_updated_at_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisition_histories_updated_at_index ON public.non_requisition_histories USING btree (updated_at);


--
-- Name: non_requisition_items_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisition_items_created_at_idx ON public.non_requisition_items USING btree (created_at DESC);


--
-- Name: non_requisition_items_name_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisition_items_name_index ON public.non_requisition_items USING btree (name);


--
-- Name: non_requisition_items_non_requisition_id_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisition_items_non_requisition_id_index ON public.non_requisition_items USING btree (non_requisition_id);


--
-- Name: non_requisitions_charge_to_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisitions_charge_to_index ON public.non_requisitions USING btree (charge_to, charge_to_id);


--
-- Name: non_requisitions_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisitions_created_at_idx ON public.non_requisitions USING btree (created_at DESC);


--
-- Name: non_requisitions_created_by_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisitions_created_by_index ON public.non_requisitions USING btree (created_by);


--
-- Name: non_requisitions_draft_non_rs_number_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisitions_draft_non_rs_number_index ON public.non_requisitions USING btree (draft_non_rs_number);


--
-- Name: non_requisitions_invoice_no_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisitions_invoice_no_index ON public.non_requisitions USING btree (invoice_no);


--
-- Name: non_requisitions_non_rs_letter_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisitions_non_rs_letter_index ON public.non_requisitions USING btree (non_rs_letter);


--
-- Name: non_requisitions_non_rs_number_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisitions_non_rs_number_index ON public.non_requisitions USING btree (non_rs_number);


--
-- Name: non_requisitions_status_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX non_requisitions_status_index ON public.non_requisitions USING btree (status);


--
-- Name: notes_created_at; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX notes_created_at ON public.notes USING btree (created_at);


--
-- Name: notes_model_model_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX notes_model_model_id ON public.notes USING btree (model, model_id);


--
-- Name: notifications_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX notifications_created_at_idx ON public.notifications USING btree (created_at);


--
-- Name: notifications_recipient_role_id_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX notifications_recipient_role_id_idx ON public.notifications USING btree (recipient_role_id);


--
-- Name: notifications_recipient_user_ids_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX notifications_recipient_user_ids_idx ON public.notifications USING gin (recipient_user_ids);


--
-- Name: notifications_type_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX notifications_type_idx ON public.notifications USING btree (type);


--
-- Name: permissions_module_action; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE UNIQUE INDEX permissions_module_action ON public.permissions USING btree (module, action);


--
-- Name: po_cancelled_items_canvass_item_id_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX po_cancelled_items_canvass_item_id_index ON public.purchase_order_cancelled_items USING btree (canvass_item_id);


--
-- Name: po_cancelled_items_po_id_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX po_cancelled_items_po_id_index ON public.purchase_order_cancelled_items USING btree (purchase_order_id);


--
-- Name: po_cancelled_items_requisition_composite_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX po_cancelled_items_requisition_composite_index ON public.purchase_order_cancelled_items USING btree (canvass_requisition_id, requisition_item_list_id);


--
-- Name: po_cancelled_items_requisition_id_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX po_cancelled_items_requisition_id_index ON public.purchase_order_cancelled_items USING btree (requisition_id);


--
-- Name: po_cancelled_items_supplier_composite_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX po_cancelled_items_supplier_composite_index ON public.purchase_order_cancelled_items USING btree (supplier_id, supplier_type);


--
-- Name: project_approvals_approval_type_code; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX project_approvals_approval_type_code ON public.project_approvals USING btree (approval_type_code);


--
-- Name: project_approvals_approver_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX project_approvals_approver_id ON public.project_approvals USING btree (approver_id);


--
-- Name: project_approvals_level; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX project_approvals_level ON public.project_approvals USING btree (level);


--
-- Name: project_approvals_proj_type_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX project_approvals_proj_type_idx ON public.project_approvals USING btree (project_id, approval_type_code);


--
-- Name: project_approvals_project_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX project_approvals_project_id ON public.project_approvals USING btree (project_id);


--
-- Name: project_companies_unique; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE UNIQUE INDEX project_companies_unique ON public.project_companies USING btree (project_id, company_id);


--
-- Name: projects_code; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE UNIQUE INDEX projects_code ON public.projects USING btree (code);


--
-- Name: projects_company_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX projects_company_id ON public.projects USING btree (company_id);


--
-- Name: projects_name; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX projects_name ON public.projects USING btree (name);


--
-- Name: projects_trades_engineer_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX projects_trades_engineer_id ON public.projects_trades USING btree (engineer_id);


--
-- Name: projects_trades_project_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX projects_trades_project_id ON public.projects_trades USING btree (project_id);


--
-- Name: projects_trades_trade_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX projects_trades_trade_id ON public.projects_trades USING btree (trade_id);


--
-- Name: purchase_order_approvers_alt_approver_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_order_approvers_alt_approver_id ON public.purchase_order_approvers USING btree (alt_approver_id);


--
-- Name: purchase_order_approvers_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_order_approvers_created_at_idx ON public.purchase_order_approvers USING btree (created_at DESC);


--
-- Name: purchase_order_approvers_level; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_order_approvers_level ON public.purchase_order_approvers USING btree (level);


--
-- Name: purchase_order_approvers_purchase_order_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_order_approvers_purchase_order_id ON public.purchase_order_approvers USING btree (purchase_order_id);


--
-- Name: purchase_order_approvers_role_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_order_approvers_role_id ON public.purchase_order_approvers USING btree (role_id);


--
-- Name: purchase_order_approvers_status; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_order_approvers_status ON public.purchase_order_approvers USING btree (status);


--
-- Name: purchase_order_approvers_user_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_order_approvers_user_id ON public.purchase_order_approvers USING btree (user_id);


--
-- Name: purchase_order_cancelled_items_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_order_cancelled_items_created_at_idx ON public.purchase_order_cancelled_items USING btree (created_at DESC);


--
-- Name: purchase_order_items_canvass_item_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_order_items_canvass_item_id ON public.purchase_order_items USING btree (canvass_item_id);


--
-- Name: purchase_order_items_canvass_item_supplier_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_order_items_canvass_item_supplier_id ON public.purchase_order_items USING btree (canvass_item_supplier_id);


--
-- Name: purchase_order_items_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_order_items_created_at_idx ON public.purchase_order_items USING btree (created_at DESC);


--
-- Name: purchase_order_items_purchase_order_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_order_items_purchase_order_id ON public.purchase_order_items USING btree (purchase_order_id);


--
-- Name: purchase_order_items_requisition_item_list_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_order_items_requisition_item_list_id ON public.purchase_order_items USING btree (requisition_item_list_id);


--
-- Name: purchase_orders_canvass_requisition_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_orders_canvass_requisition_id ON public.purchase_orders USING btree (canvass_requisition_id);


--
-- Name: purchase_orders_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_orders_created_at_idx ON public.purchase_orders USING btree (created_at DESC);


--
-- Name: purchase_orders_po_letter; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_orders_po_letter ON public.purchase_orders USING btree (po_letter);


--
-- Name: purchase_orders_po_number; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_orders_po_number ON public.purchase_orders USING btree (po_number);


--
-- Name: purchase_orders_requisition_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_orders_requisition_id ON public.purchase_orders USING btree (requisition_id);


--
-- Name: purchase_orders_status; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_orders_status ON public.purchase_orders USING btree (status);


--
-- Name: purchase_orders_supplier_id_supplier_type; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX purchase_orders_supplier_id_supplier_type ON public.purchase_orders USING btree (supplier_id, supplier_type);


--
-- Name: requisition_approvers_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisition_approvers_created_at_idx ON public.requisition_approvers USING btree (created_at DESC);


--
-- Name: requisition_badges_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisition_badges_created_at_idx ON public.requisition_badges USING btree (created_at DESC);


--
-- Name: requisition_badges_requisition_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisition_badges_requisition_id ON public.requisition_badges USING btree (requisition_id);


--
-- Name: requisition_canvass_histories_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisition_canvass_histories_created_at_idx ON public.requisition_canvass_histories USING btree (created_at DESC);


--
-- Name: requisition_canvass_histories_requisition_item_list_id_supplier; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisition_canvass_histories_requisition_item_list_id_supplier ON public.requisition_canvass_histories USING btree (requisition_item_list_id, supplier_id, canvass_requisition_id);


--
-- Name: requisition_delivery_histories_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisition_delivery_histories_created_at_idx ON public.requisition_delivery_histories USING btree (created_at DESC);


--
-- Name: requisition_item_histories_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisition_item_histories_created_at_idx ON public.requisition_item_histories USING btree (created_at DESC);


--
-- Name: requisition_item_lists_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisition_item_lists_created_at_idx ON public.requisition_item_lists USING btree (created_at DESC);


--
-- Name: requisition_number_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisition_number_index ON public.requisitions USING btree (company_code, rs_letter, rs_number);


--
-- Name: requisition_order_histories_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisition_order_histories_created_at_idx ON public.requisition_order_histories USING btree (created_at DESC);


--
-- Name: requisition_payment_histories_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisition_payment_histories_created_at_idx ON public.requisition_payment_histories USING btree (created_at DESC);


--
-- Name: requisition_return_histories_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisition_return_histories_created_at_idx ON public.requisition_return_histories USING btree (created_at DESC);


--
-- Name: requisitions_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisitions_created_at_idx ON public.requisitions USING btree (created_at DESC);


--
-- Name: requisitions_status_index; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX requisitions_status_index ON public.requisitions USING btree (status);


--
-- Name: role_permissions_role_id_permission_id; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE UNIQUE INDEX role_permissions_role_id_permission_id ON public.role_permissions USING btree (role_id, permission_id);


--
-- Name: rs_payment_request_approvers_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX rs_payment_request_approvers_created_at_idx ON public.rs_payment_request_approvers USING btree (created_at DESC);


--
-- Name: rs_payment_requests_created_at_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX rs_payment_requests_created_at_idx ON public.rs_payment_requests USING btree (created_at DESC);


--
-- Name: unique_canvass_item_supplier_with_time; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE UNIQUE INDEX unique_canvass_item_supplier_with_time ON public.canvass_item_suppliers USING btree (canvass_item_id, supplier_id, created_at);


--
-- Name: unique_canvass_requisition_item_with_time; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE UNIQUE INDEX unique_canvass_requisition_item_with_time ON public.canvass_items USING btree (canvass_requisition_id, requisition_item_list_id, created_at);


--
-- Name: unique_canvass_role; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX unique_canvass_role ON public.canvass_approvers USING btree (canvass_requisition_id, role_id) WHERE (role_id IS NOT NULL);


--
-- Name: unique_project_trade_engineer; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE UNIQUE INDEX unique_project_trade_engineer ON public.projects_trades USING btree (project_id, trade_id, engineer_id);


--
-- Name: users_supervisor_id_idx; Type: INDEX; Schema: public; Owner: prs_user
--

CREATE INDEX users_supervisor_id_idx ON public.users USING btree (supervisor_id);


--
-- Name: _compressed_hypertable_38 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_38 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_39 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_39 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_40 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_40 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_41 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_41 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_42 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_42 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_43 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_43 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_44 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_44 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_45 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_45 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_46 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_46 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_47 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_47 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_48 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_48 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_49 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_49 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_50 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_50 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_51 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_51 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_52 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_52 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_53 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_53 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_54 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_54 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_55 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_55 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_56 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_56 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_57 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_57 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_58 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_58 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_59 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_59 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_60 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_60 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_61 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_61 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_62 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_62 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_63 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_63 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_64 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_64 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_65 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_65 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_66 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_66 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_67 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_67 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_68 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_68 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_69 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_69 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_70 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_70 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_71 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_71 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_72 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_72 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: _compressed_hypertable_73 ts_insert_blocker; Type: TRIGGER; Schema: _timescaledb_internal; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON _timescaledb_internal._compressed_hypertable_73 FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: attachments ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.attachments FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: audit_logs ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.audit_logs FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: canvass_approvers ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.canvass_approvers FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: canvass_item_suppliers ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.canvass_item_suppliers FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: canvass_items ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.canvass_items FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: canvass_requisitions ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.canvass_requisitions FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: comments ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.comments FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: delivery_receipt_invoices ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.delivery_receipt_invoices FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: delivery_receipt_items ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.delivery_receipt_items FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: delivery_receipt_items_history ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.delivery_receipt_items_history FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: delivery_receipts ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.delivery_receipts FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: force_close_logs ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.force_close_logs FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: histories ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.histories FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: invoice_report_histories ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.invoice_report_histories FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: invoice_reports ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.invoice_reports FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: non_requisition_approvers ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.non_requisition_approvers FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: non_requisition_histories ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.non_requisition_histories FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: non_requisition_items ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.non_requisition_items FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: non_requisitions ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.non_requisitions FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: notes ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.notes FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: notifications ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.notifications FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: purchase_order_approvers ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.purchase_order_approvers FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: purchase_order_cancelled_items ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.purchase_order_cancelled_items FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: purchase_order_items ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.purchase_order_items FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: purchase_orders ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.purchase_orders FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: requisition_approvers ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.requisition_approvers FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: requisition_badges ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.requisition_badges FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: requisition_canvass_histories ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.requisition_canvass_histories FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: requisition_delivery_histories ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.requisition_delivery_histories FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: requisition_item_histories ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.requisition_item_histories FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: requisition_item_lists ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.requisition_item_lists FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: requisition_order_histories ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.requisition_order_histories FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: requisition_payment_histories ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.requisition_payment_histories FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: requisition_return_histories ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.requisition_return_histories FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: requisitions ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.requisitions FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: rs_payment_request_approvers ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.rs_payment_request_approvers FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: rs_payment_requests ts_insert_blocker; Type: TRIGGER; Schema: public; Owner: prs_user
--

CREATE TRIGGER ts_insert_blocker BEFORE INSERT ON public.rs_payment_requests FOR EACH ROW EXECUTE FUNCTION _timescaledb_functions.insert_blocker();


--
-- Name: attachment_badges attachment_badges_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.attachment_badges
    ADD CONSTRAINT attachment_badges_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: comment_badges comment_badges_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.comment_badges
    ADD CONSTRAINT comment_badges_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: department_approvals department_approvals_approval_type_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.department_approvals
    ADD CONSTRAINT department_approvals_approval_type_code_fkey FOREIGN KEY (approval_type_code) REFERENCES public.approval_types(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: department_approvals department_approvals_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.department_approvals
    ADD CONSTRAINT department_approvals_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(id) ON UPDATE CASCADE;


--
-- Name: department_approvals department_approvals_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.department_approvals
    ADD CONSTRAINT department_approvals_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: department_association_approvals department_association_approvals_approval_type_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.department_association_approvals
    ADD CONSTRAINT department_association_approvals_approval_type_code_fkey FOREIGN KEY (approval_type_code) REFERENCES public.approval_types(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: department_association_approvals department_association_approvals_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.department_association_approvals
    ADD CONSTRAINT department_association_approvals_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(id) ON UPDATE CASCADE;


--
-- Name: note_badges note_badges_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.note_badges
    ADD CONSTRAINT note_badges_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: project_approvals project_approvals_approval_type_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.project_approvals
    ADD CONSTRAINT project_approvals_approval_type_code_fkey FOREIGN KEY (approval_type_code) REFERENCES public.approval_types(code) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: project_approvals project_approvals_approver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.project_approvals
    ADD CONSTRAINT project_approvals_approver_id_fkey FOREIGN KEY (approver_id) REFERENCES public.users(id) ON UPDATE CASCADE;


--
-- Name: project_approvals project_approvals_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.project_approvals
    ADD CONSTRAINT project_approvals_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: project_companies project_companies_company_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.project_companies
    ADD CONSTRAINT project_companies_company_id_fkey FOREIGN KEY (company_id) REFERENCES public.companies(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: project_companies project_companies_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.project_companies
    ADD CONSTRAINT project_companies_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: projects_trades projects_trades_engineer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.projects_trades
    ADD CONSTRAINT projects_trades_engineer_id_fkey FOREIGN KEY (engineer_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: projects_trades projects_trades_project_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.projects_trades
    ADD CONSTRAINT projects_trades_project_id_fkey FOREIGN KEY (project_id) REFERENCES public.projects(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: projects_trades projects_trades_trade_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.projects_trades
    ADD CONSTRAINT projects_trades_trade_id_fkey FOREIGN KEY (trade_id) REFERENCES public.trades(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_permission_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: role_permissions role_permissions_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.role_permissions
    ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: suppliers suppliers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.suppliers
    ADD CONSTRAINT suppliers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: users users_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: users users_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: users users_supervisor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: prs_user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_supervisor_id_fkey FOREIGN KEY (supervisor_id) REFERENCES public.users(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

