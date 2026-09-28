# Madhu Enterprises — Final Master Build

## Production setup
1. Use the existing Supabase project only. Run `phase3-complete.sql` once; it is additive and preserves existing products/orders.
2. Enable Supabase Auth providers required by the site: Email, Phone/SMS OTP, and Google OAuth. Configure production redirect URLs for the final HTTPS domain.
3. Keep service-role/secret keys only in Supabase Edge Function secrets. The browser uses only the publishable/anon key.
4. Deploy this folder to the existing Netlify site. Do not create a new Netlify project.
5. After the custom domain is connected, update the canonical/OG URLs, sitemap and Supabase Auth Site URL/redirect allow-list to that exact HTTPS domain.

## Local admin UI test (no Supabase / no Netlify)
Open `admin.html` directly from this folder. On localhost/file mode only, the local demo login is: 
- Username: `admin`
- Password: `MadhuAdmin@2026`

This demo credential is deliberately disabled on hosted production pages. It is UI-only and does not access real customer/order data.

## Customer order rules
- Customer cancellation: pending/confirmed/processing/packed only.
- Customer return: delivered only.
- Admin can confirm, reject, cancel, ship, deliver, approve/reject returns and process refunds through the configured payment backend.

## SEO
`robots.txt`, `sitemap.xml`, canonical/OG metadata and local/product SEO are included. Submit the sitemap in Google Search Console after production domain setup.

## Final review and authentication notes
- Product cards open the product directly; there is no customer-facing "View Details" button.
- A review can only be submitted through the verified review RPC after the signed-in customer has an order containing that product whose status is `delivered`.
- Review insert/update is not available directly to normal authenticated clients; the RPC enforces delivery eligibility server-side.
- Mobile OTP requires Supabase Phone Auth plus an SMS provider (for example Twilio/Vonage/MessageBird). The website code is production-ready for the configured provider but cannot send SMS without that provider configuration.
- Google login requires enabling Google in Supabase Auth and configuring the production OAuth callback/redirect URL. The website uses the current production origin for the redirect.
- Email/password registration uses Supabase Auth email verification when Confirm Email is enabled. Password reset uses the production site URL.
- Invoice rendering uses the secure `get_order_invoice` RPC so customer/admin RLS does not expose raw invoice/order rows.

## Final authentication + refund configuration

Customer login supports email/password + email verification, Google OAuth, and phone OTP. Supabase Phone Auth requires an SMS provider; Google requires the Google provider and exact production redirect URL. Supabase recommends rate limits/CAPTCHA for production OTP.

COD returns use RazorpayX Payout Links: Admin approves/receives the return, then the Admin panel creates a payout link. The customer receives the link, verifies by OTP, enters bank/UPI details, and the refund is processed. Razorpay documents Payout Links specifically for COD refunds.

Add these as Supabase Edge Function secrets before live COD payout refunds:
- `RAZORPAYX_KEY_ID`
- `RAZORPAYX_KEY_SECRET`
- `RAZORPAYX_ACCOUNT_NUMBER` (RazorpayX Customer Identifier / source account)

Never put these secrets in frontend HTML/JS.
