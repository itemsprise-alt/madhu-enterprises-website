# Madhu Enterprises V3 setup

## Supabase SQL
Run `phase3-complete.sql` once in SQL Editor. It adds secure invoice, customer order and admin login-activity functions.

## Mobile OTP
In Supabase Dashboard -> Authentication -> Providers -> Phone, enable Phone and configure an SMS provider (Twilio, Vonage, or MessageBird). The website UI is already prepared. Without an SMS provider, Supabase returns `Unsupported phone provider`.

## Google Login
The website button is prepared. In Supabase Authentication -> Providers -> Google, configure Google OAuth Client ID/Secret from Google Cloud. Add the Netlify site URL as an authorized JavaScript origin and use the callback URL shown by Supabase for the authorized redirect URI. Also set the Supabase Auth URL Configuration Site URL to the production Netlify/custom-domain URL.

## Login activity
The admin panel has a Login Activity section backed by Supabase Auth audit logs. Supabase automatically captures sign-ins/sign-ups; the SQL function reads the latest event for each user.

## Invoice
Invoice now uses a secure authenticated RPC, so customer/admin RLS does not make the invoice appear blank or `Order not found`.


### Order/SKU behavior update
- Internal SKU is stored for admin use only. Customer product search deliberately excludes SKU.
- Order items snapshot the SKU at checkout so the admin order details and invoice keep the SKU even if the product record later changes.
- Customer cancellation now also supports the packed state.
- Admin order details include a complete-invoice panel; the invoice always reflects the current order status, including Cancelled.
