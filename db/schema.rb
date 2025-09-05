# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_09_05_204921) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "affiliate_conversions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "external_id", null: false
    t.string "order_id"
    t.string "item_id"
    t.string "category"
    t.string "channel"
    t.string "sub_id"
    t.integer "commission_cents", default: 0
    t.string "currency", default: "BRL"
    t.integer "quantity", default: 1
    t.datetime "click_time"
    t.datetime "conversion_time"
    t.string "status"
    t.string "source", default: "shopee_api"
    t.json "raw_data"
    t.decimal "purchase_value", precision: 10, scale: 2
    t.decimal "commission_rate", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["conversion_time"], name: "index_affiliate_conversions_on_conversion_time"
    t.index ["order_id"], name: "index_affiliate_conversions_on_order_id"
    t.index ["source"], name: "index_affiliate_conversions_on_source"
    t.index ["status"], name: "index_affiliate_conversions_on_status"
    t.index ["sub_id"], name: "index_affiliate_conversions_on_sub_id"
    t.index ["user_id", "external_id"], name: "index_affiliate_conversions_on_user_id_and_external_id", unique: true
    t.index ["user_id"], name: "index_affiliate_conversions_on_user_id"
  end

  create_table "commissions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "order_id", null: false
    t.string "sub_id"
    t.string "channel"
    t.decimal "commission_amount", precision: 10, scale: 2
    t.decimal "sale_amount", precision: 10, scale: 2
    t.string "order_status"
    t.string "commission_type"
    t.string "product_name", limit: 500
    t.string "category"
    t.datetime "order_date"
    t.datetime "commission_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "payment_id"
    t.datetime "completion_time"
    t.datetime "click_time"
    t.string "store_name"
    t.string "store_id"
    t.string "store_type"
    t.string "item_id"
    t.string "item_name"
    t.string "product_type"
    t.string "category_l1"
    t.string "category_l2"
    t.string "category_l3"
    t.decimal "price"
    t.integer "quantity"
    t.decimal "purchase_value"
    t.decimal "refund_value"
    t.decimal "shopee_commission_rate"
    t.decimal "shopee_commission"
    t.decimal "seller_commission_rate"
    t.decimal "seller_commission"
    t.decimal "total_item_commission"
    t.decimal "total_order_commission"
    t.decimal "affiliate_commission"
    t.string "affiliate_status"
    t.string "attribution_type"
    t.string "buyer_status"
    t.string "sub_id1"
    t.string "sub_id2"
    t.string "sub_id3"
    t.string "sub_id4"
    t.string "sub_id5"
    t.string "external_id"
    t.string "source", default: "csv"
    t.index ["channel"], name: "index_commissions_on_channel"
    t.index ["commission_date"], name: "index_commissions_on_commission_date"
    t.index ["external_id"], name: "index_commissions_on_external_id"
    t.index ["order_date"], name: "index_commissions_on_order_date"
    t.index ["order_id"], name: "index_commissions_on_order_id"
    t.index ["source"], name: "index_commissions_on_source"
    t.index ["user_id", "order_id"], name: "index_commissions_on_user_id_and_order_id", unique: true
    t.index ["user_id"], name: "index_commissions_on_user_id"
  end

  create_table "devices", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "device_id", null: false
    t.string "device_type"
    t.string "browser"
    t.string "os"
    t.inet "ip_address"
    t.text "user_agent"
    t.datetime "last_seen_at"
    t.boolean "trusted", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["device_id"], name: "index_devices_on_device_id", unique: true
    t.index ["last_seen_at"], name: "index_devices_on_last_seen_at"
    t.index ["trusted"], name: "index_devices_on_trusted"
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "links", force: :cascade do |t|
    t.string "short_code", null: false
    t.text "original_url", null: false
    t.string "title"
    t.text "description"
    t.integer "clicks_count", default: 0
    t.boolean "active", default: true
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.string "custom_slug"
    t.text "tags"
    t.datetime "expires_at"
    t.boolean "advanced_tracking"
    t.index ["active"], name: "index_links_on_active"
    t.index ["clicks_count"], name: "index_links_on_clicks_count"
    t.index ["short_code"], name: "index_links_on_short_code", unique: true
    t.index ["user_id"], name: "index_links_on_user_id"
  end

  create_table "plans", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "price_cents", null: false
    t.string "currency", default: "BRL"
    t.string "stripe_price_id"
    t.integer "max_links"
    t.json "features"
    t.boolean "popular", default: false
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_plans_on_active"
    t.index ["name"], name: "index_plans_on_name"
    t.index ["popular"], name: "index_plans_on_popular"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key"
    t.text "value"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "shopee_affiliate_integrations", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "app_id", null: false
    t.text "encrypted_secret"
    t.string "encrypted_secret_iv"
    t.string "market", default: "BR"
    t.string "endpoint", default: "https://open-api.affiliate.shopee.com.br/graphql"
    t.datetime "last_sync_at"
    t.boolean "active", default: true
    t.text "last_error"
    t.integer "sync_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "shopee_user_id"
    t.text "encrypted_access_token"
    t.string "encrypted_access_token_iv"
    t.text "encrypted_refresh_token"
    t.string "encrypted_refresh_token_iv"
    t.datetime "token_expires_at"
    t.string "auth_type", default: "individual"
    t.index ["app_id"], name: "index_shopee_integrations_on_app_id"
    t.index ["auth_type"], name: "index_shopee_affiliate_integrations_on_auth_type"
    t.index ["shopee_user_id"], name: "index_shopee_affiliate_integrations_on_shopee_user_id"
    t.index ["user_id"], name: "index_shopee_affiliate_integrations_on_user_id"
    t.index ["user_id"], name: "index_shopee_integrations_on_user_id", unique: true
  end

  create_table "shopee_api_requests", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "shopee_master_config_id", null: false
    t.string "endpoint", null: false
    t.string "method", null: false
    t.integer "status_code", null: false
    t.integer "response_time_ms"
    t.text "error_message"
    t.json "request_params"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_shopee_api_requests_on_created_at"
    t.index ["shopee_master_config_id", "created_at"], name: "idx_on_shopee_master_config_id_created_at_8a17d7f363"
    t.index ["shopee_master_config_id"], name: "index_shopee_api_requests_on_shopee_master_config_id"
    t.index ["status_code"], name: "index_shopee_api_requests_on_status_code"
    t.index ["user_id", "created_at"], name: "index_shopee_api_requests_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_shopee_api_requests_on_user_id"
  end

  create_table "shopee_master_configs", force: :cascade do |t|
    t.string "market", default: "BR", null: false
    t.text "endpoint", null: false
    t.text "encrypted_master_app_id"
    t.string "encrypted_master_app_id_iv"
    t.text "encrypted_master_secret"
    t.string "encrypted_master_secret_iv"
    t.boolean "active", default: false
    t.integer "rate_limit_per_minute", default: 100
    t.integer "rate_limit_per_hour", default: 5000
    t.datetime "last_tested_at"
    t.text "last_test_result"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_shopee_master_configs_on_active"
    t.index ["market", "active"], name: "index_shopee_master_configs_on_market_and_active"
    t.index ["market"], name: "index_shopee_master_configs_on_market"
  end

  create_table "subid_ad_spends", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "subid"
    t.decimal "ad_spend"
    t.decimal "total_investment"
    t.date "period_start"
    t.date "period_end"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_subid_ad_spends_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "plan_id", null: false
    t.string "stripe_subscription_id"
    t.string "stripe_customer_id"
    t.string "status", default: "active"
    t.datetime "current_period_start"
    t.datetime "current_period_end"
    t.datetime "trial_ends_at"
    t.datetime "canceled_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["current_period_end"], name: "index_subscriptions_on_current_period_end"
    t.index ["plan_id"], name: "index_subscriptions_on_plan_id"
    t.index ["status"], name: "index_subscriptions_on_status"
    t.index ["stripe_customer_id"], name: "index_subscriptions_on_stripe_customer_id"
    t.index ["stripe_subscription_id"], name: "index_subscriptions_on_stripe_subscription_id", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "first_name"
    t.string "last_name"
    t.string "phone"
    t.datetime "trial_ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "subscription_id"
    t.string "role"
    t.string "stripe_customer_id"
    t.boolean "stripe_setup_needed"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["subscription_id"], name: "index_users_on_subscription_id"
  end

  create_table "website_clicks", force: :cascade do |t|
    t.string "click_id"
    t.datetime "click_time"
    t.string "region"
    t.string "sub_id"
    t.string "referrer"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_website_clicks_on_user_id"
  end

  add_foreign_key "affiliate_conversions", "users"
  add_foreign_key "commissions", "users"
  add_foreign_key "devices", "users"
  add_foreign_key "links", "users"
  add_foreign_key "shopee_affiliate_integrations", "users"
  add_foreign_key "shopee_api_requests", "shopee_master_configs"
  add_foreign_key "shopee_api_requests", "users"
  add_foreign_key "subid_ad_spends", "users"
  add_foreign_key "subscriptions", "plans"
  add_foreign_key "subscriptions", "users"
  add_foreign_key "users", "subscriptions"
  add_foreign_key "website_clicks", "users"
end
