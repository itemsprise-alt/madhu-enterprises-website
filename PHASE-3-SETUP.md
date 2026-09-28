# Madhu Enterprises — Complete E-commerce Setup

This is the **same FINAL MASTER project**, upgraded with the complete customer/order/payment foundation.

## 1. Where customer/order data is stored

The website uses **Supabase Postgres + Supabase Auth**.

- `auth.users` — customer login identity/email.
- `profiles` — customer profile/name/phone/role.
- `addresses` — saved delivery addresses.
- `orders` — one row per order: customer, address snapshot, subtotal, discount, shipping, total, payment method, payment status, order status, tracking, cancellation data.
- `order_items` — every product/quantity/price in each order.
- `payments` — Razorpay payment IDs, amount, method, paid/refund status and gateway references.
- `order_status_history` — status timeline.
- `return_requests` — customer return requests.
- `refund_requests` — refund workflow.
- `loyalty_ledger` — future/active loyalty points ledger.
- `wishlists`, `reviews`, `notifications` — existing customer features.

The browser never stores card/UPI credentials. Razorpay handles the payment instrument. Keep the Razorpay secret on the server/Edge Function only.

## 2. Run the database migration

Open Supabase → SQL Editor → paste/run:

`phase3-complete.sql`

It is designed as a non-destructive migration and does not delete existing products.

## 3. Deploy Supabase Edge Functions

Functions included:

- `create-razorpay-order`
- `verify-razorpay-payment`
- `razorpay-webhook`
- `refund-razorpay-payment`

Deploy them using Supabase CLI from the project root, or create/deploy the same functions in Supabase Dashboard.

## 4. Razorpay setup

You need a Razorpay merchant account and activation/KYC. Razorpay's current gateway supports UPI, cards and net banking, and provides APIs and webhooks for payment reconciliation.

Create these **Supabase Edge Function secrets**:

- `RAZORPAY_KEY_ID` = Razorpay live/test Key ID
- `RAZORPAY_KEY_SECRET` = Razorpay secret
- `RAZORPAY_WEBHOOK_SECRET` = secret chosen for the webhook
- `SUPABASE_SERVICE_ROLE_KEY` = your Supabase service-role secret (server-side only)

Do **not** put `RAZORPAY_KEY_SECRET` or `SUPABASE_SERVICE_ROLE_KEY` into HTML/JavaScript or Git.

Configure Razorpay webhook URL:

`https://YOUR_PROJECT_REF.supabase.co/functions/v1/razorpay-webhook`

Subscribe at minimum to payment captured, payment failed and refund processed events.

## 5. Netlify

Do **not** create a new Netlify site. Deploy this project to the existing Madhu Enterprises site.

## 6. Customer flow

Product → Add to Cart → +/- quantity → Remove → Checkout → Address → COD/Online → Order created → inventory reserved → payment confirmation → My Orders → tracking → cancellation/return → invoice/refund.

## 7. Admin flow

Admin → Orders shows customer, total, payment method/status, order status, tracking and refund action.

Admin → Customers shows total orders, delivered, cancelled, spend and last order.

Admin → Returns & Refunds handles return requests.

## 8. Important production checks

Before accepting real money, test the complete flow with Razorpay Test Mode:

1. Customer registration/login.
2. Add two products.
3. Change quantity +/−.
4. Remove a product.
5. COD order.
6. Online test payment.
7. Failed payment.
8. Customer cancellation.
9. Paid-order cancellation → refund request.
10. Admin refund.
11. Delivery/tracking status.
12. Return request.
13. Invoice.
14. Account deletion/anonymisation behavior.

Only after these tests pass should Razorpay be switched to Live Mode.

## Customer login + professional order management update

The latest master build adds:
- Mobile OTP login UI (Supabase Phone Auth / SMS provider required).
- Forgot-password email flow.
- Complete customer order cards with items, delivery address, payment status, tracking, invoice, cancellation, return request and status timeline.
- Robust order read RPCs (`get_my_orders_full`, `get_admin_orders_full`) so the site does not depend on Supabase relationship auto-discovery for customer/order details.
- Admin order detail drawer/row showing customer contact, full address, item lines, payment/gateway IDs, status history, returns/refunds and customer notes.

For Mobile OTP in production, enable Supabase Phone Auth and configure an SMS provider. Supabase documents phone OTP via `signInWithOtp({ phone })` and `verifyOtp({ phone, token, type: 'sms' })`. India SMS sending can require provider/regulatory configuration.
