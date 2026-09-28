# Madhu Enterprises — FINAL MASTER deployment checklist

## Included in this master
- Customer storefront + responsive mobile UI
- Premium themed customer account/dashboard
- Wishlist + shareable wishlist
- Product share
- Smart search/filtering
- Product detail + up to 8 images
- Cart with +/- quantity and Remove
- Buy Now
- Checkout
- COD
- Razorpay online-payment integration (server-side verification/webhook/refund functions)
- Customer order history
- Customer cancellation
- Return request
- Invoice
- Admin customer records
- Admin order/payment dashboard
- Pending/confirmed/processing/packed/shipped/out-for-delivery/delivered/cancelled/return/refunded states
- Tracking number + carrier
- Refund workflow
- Order status history
- Inventory reservation/release
- Coupons, reviews, notifications, analytics and existing product manager
- Local logo fallback at `images/madhu-logo.jpg`

## Required one-time live setup
1. Run `phase3-complete.sql` in the existing Supabase project's SQL Editor.
2. Deploy the four Edge Functions under `supabase/functions/`.
3. In Supabase Edge Function secrets configure:
   - `RAZORPAY_KEY_ID`
   - `RAZORPAY_KEY_SECRET`
   - `RAZORPAY_WEBHOOK_SECRET`
   - `SUPABASE_SERVICE_ROLE_KEY`
4. Configure the Razorpay webhook URL:
   `https://ozwnmiiakzdrddkmdccl.supabase.co/functions/v1/razorpay-webhook`
5. Test in Razorpay Test Mode before Live Mode.
6. Deploy this folder to the EXISTING Netlify site; do not create another Netlify site.

## Payment safety
- Card/UPI credentials are handled by Razorpay, not stored by the storefront.
- Razorpay secret and Supabase service-role key are server-side secrets only.
- Never paste either secret into HTML/JavaScript.

## Final acceptance test
- Registration/login
- Add to cart
- +/- quantity
- Remove from cart
- COD order
- Online test payment
- Failed payment
- Customer cancellation
- Paid-order refund
- Admin status change
- Tracking update
- Delivered order
- Return request
- Invoice
- Customer order statistics
- Admin order statistics
- Logo visible on fresh device/browser

## Latest customer-account/order-management update

After running the latest `phase3-complete.sql`, verify:
- Customer account shows My Orders automatically.
- Each order shows item lines, address, payment state, status timeline and invoice.
- Pending/confirmed/processing/packed orders can be cancelled through `cancel_my_order`.
- Delivered orders can submit a return request through `request_order_return`.
- Admin Orders > Details shows customer contact, address, items, status history, return/refund information and payment gateway IDs.
- If the UI says `get_my_orders_full` or `get_admin_orders_full` is missing, the latest SQL migration has not been run yet.
- Mobile OTP requires Supabase Phone Auth + an SMS provider; it is not enabled merely by adding a phone field to `profiles`.
