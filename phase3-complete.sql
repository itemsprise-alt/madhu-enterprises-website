-- Madhu Enterprises - additive Phase 3 e-commerce migration
-- Non-destructive: does not delete products or customer records.

create extension if not exists pgcrypto;

-- ---------- Core customer profile additions ----------
alter table public.profiles add column if not exists phone text;
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists last_login_at timestamptz;

-- ---------- Orders ----------
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text unique,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending',
  payment_method text not null default 'cod',
  payment_status text not null default 'pending',
  subtotal numeric(12,2) not null default 0,
  discount numeric(12,2) not null default 0,
  shipping_fee numeric(12,2) not null default 0,
  total numeric(12,2) not null default 0,
  coupon_code text,
  shipping_name text not null default '',
  shipping_phone text not null default '',
  shipping_line1 text not null default '',
  shipping_line2 text,
  shipping_city text not null default '',
  shipping_state text not null default '',
  shipping_pincode text not null default '',
  customer_note text,
  placed_at timestamptz not null default now(),
  confirmed_at timestamptz,
  packed_at timestamptz,
  shipped_at timestamptz,
  out_for_delivery_at timestamptz,
  delivered_at timestamptz,
  cancelled_at timestamptz,
  cancellation_reason text,
  cancelled_by text,
  tracking_number text,
  carrier text,
  estimated_delivery date,
  inventory_reserved boolean not null default false,
  refund_status text not null default 'not_requested',
  refund_amount numeric(12,2) not null default 0,
  refunded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.orders add column if not exists order_number text;
alter table public.orders add column if not exists user_id uuid;
alter table public.orders add column if not exists status text not null default 'pending';
alter table public.orders add column if not exists payment_method text not null default 'cod';
alter table public.orders add column if not exists payment_status text not null default 'pending';
alter table public.orders add column if not exists subtotal numeric(12,2) not null default 0;
alter table public.orders add column if not exists discount numeric(12,2) not null default 0;
alter table public.orders add column if not exists shipping_fee numeric(12,2) not null default 0;
alter table public.orders add column if not exists total numeric(12,2) not null default 0;
alter table public.orders add column if not exists coupon_code text;
alter table public.orders add column if not exists shipping_name text not null default '';
alter table public.orders add column if not exists shipping_phone text not null default '';
alter table public.orders add column if not exists shipping_line1 text not null default '';
alter table public.orders add column if not exists shipping_line2 text;
alter table public.orders add column if not exists shipping_city text not null default '';
alter table public.orders add column if not exists shipping_state text not null default '';
alter table public.orders add column if not exists shipping_pincode text not null default '';
alter table public.orders add column if not exists customer_note text;
alter table public.orders add column if not exists placed_at timestamptz not null default now();
alter table public.orders add column if not exists confirmed_at timestamptz;
alter table public.orders add column if not exists packed_at timestamptz;
alter table public.orders add column if not exists shipped_at timestamptz;
alter table public.orders add column if not exists out_for_delivery_at timestamptz;
alter table public.orders add column if not exists delivered_at timestamptz;
alter table public.orders add column if not exists cancelled_at timestamptz;
alter table public.orders add column if not exists cancellation_reason text;
alter table public.orders add column if not exists cancelled_by text;
alter table public.orders add column if not exists tracking_number text;
alter table public.orders add column if not exists carrier text;
alter table public.orders add column if not exists estimated_delivery date;
alter table public.orders add column if not exists inventory_reserved boolean not null default false;
alter table public.orders add column if not exists gateway_order_id text;
alter table public.orders add column if not exists gateway_payment_id text;
alter table public.orders add column if not exists refund_status text not null default 'not_requested';
alter table public.orders add column if not exists refund_amount numeric(12,2) not null default 0;
alter table public.orders add column if not exists refunded_at timestamptz;
alter table public.orders add column if not exists created_at timestamptz not null default now();
alter table public.orders add column if not exists updated_at timestamptz not null default now();

-- Internal admin-only product SKU. Customer search never uses this field.
alter table public.products add column if not exists sku text;
create index if not exists products_sku_idx on public.products(sku);

create unique index if not exists orders_order_number_uidx on public.orders(order_number) where order_number is not null;
create index if not exists orders_user_idx on public.orders(user_id, placed_at desc);
create index if not exists orders_status_idx on public.orders(status, placed_at desc);
create index if not exists orders_payment_idx on public.orders(payment_status, payment_method, placed_at desc);

-- ---------- Order items ----------
create table if not exists public.order_items (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  product_id uuid,
  product_name text not null,
  sku text,
  image_url text,
  price numeric(12,2) not null default 0,
  quantity integer not null check(quantity > 0),
  line_total numeric(12,2) not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists order_items_order_idx on public.order_items(order_id);

-- ---------- Payment ledger ----------
create table if not exists public.payments (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  gateway text not null default 'razorpay',
  gateway_order_id text,
  gateway_payment_id text,
  gateway_signature text,
  amount numeric(12,2) not null default 0,
  currency text not null default 'INR',
  status text not null default 'created',
  method text,
  raw_response jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists payments_order_idx on public.payments(order_id, created_at desc);
create unique index if not exists payments_gateway_payment_uidx on public.payments(gateway_payment_id) where gateway_payment_id is not null;

-- ---------- Status history ----------
create table if not exists public.order_status_history (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  status text not null,
  note text,
  changed_by uuid,
  created_at timestamptz not null default now()
);
create index if not exists order_status_history_order_idx on public.order_status_history(order_id, created_at desc);

-- ---------- Returns / refunds ----------
create table if not exists public.return_requests (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  reason text not null,
  details text,
  status text not null default 'requested',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists return_requests_user_idx on public.return_requests(user_id, created_at desc);
create index if not exists return_requests_order_idx on public.return_requests(order_id, created_at desc);

create table if not exists public.refund_requests (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null references public.orders(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  amount numeric(12,2) not null default 0,
  reason text,
  status text not null default 'requested',
  gateway_refund_id text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists refund_requests_order_idx on public.refund_requests(order_id, created_at desc);


-- ---------- COD refund / payout workflow (additive) ----------
alter table public.orders add column if not exists refund_method text;
alter table public.orders add column if not exists refund_note text;
alter table public.orders add column if not exists payout_link_id text;
alter table public.orders add column if not exists payout_link_url text;
alter table public.orders add column if not exists payout_status text;
alter table public.orders add column if not exists payout_reference text;
alter table public.orders add column if not exists refund_requested_at timestamptz;
alter table public.orders add column if not exists refund_completed_at timestamptz;
alter table public.refund_requests add column if not exists refund_method text;
alter table public.refund_requests add column if not exists payout_link_id text;
alter table public.refund_requests add column if not exists payout_link_url text;
alter table public.refund_requests add column if not exists payout_status text;
alter table public.refund_requests add column if not exists payout_reference text;

create or replace function public.prepare_cod_refund(p_order_id uuid, p_amount numeric default null, p_reason text default 'COD refund')
returns jsonb
language plpgsql security definer set search_path=public
as $$
declare o orders%rowtype; v_amount numeric(12,2); v_id uuid;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  select * into o from public.orders where id=p_order_id for update;
  if not found then raise exception 'Order not found'; end if;
  if o.payment_method <> 'cod' then raise exception 'This workflow is only for COD orders'; end if;
  if o.status not in ('returned','refunded') and not exists(select 1 from public.return_requests rr where rr.order_id=o.id and rr.status in ('approved','received','refunded')) then
    raise exception 'COD refund is available only after an approved/received return';
  end if;
  v_amount:=least(coalesce(nullif(p_amount,0),o.total),o.total);
  if v_amount<=0 then raise exception 'Refund amount must be greater than zero'; end if;
  if o.refund_status in ('requested','payout_pending','payout_sent','processed','refunded') then raise exception 'A refund is already in progress for this order'; end if;
  insert into public.refund_requests(order_id,user_id,amount,reason,status,refund_method,created_at,updated_at)
  values(o.id,o.user_id,v_amount,coalesce(nullif(trim(p_reason),''),'COD refund'),'payout_pending','razorpayx_payout_link',now(),now())
  returning id into v_id;
  update public.orders set refund_status='requested',refund_amount=v_amount,refund_method='razorpayx_payout_link',refund_note=coalesce(nullif(trim(p_reason),''),'COD refund'),refund_requested_at=now(),updated_at=now() where id=o.id;
  return jsonb_build_object('refund_request_id',v_id,'order_id',o.id,'amount',v_amount,'status','payout_pending');
end; $$;
revoke all on function public.prepare_cod_refund(uuid,numeric,text) from public;
grant execute on function public.prepare_cod_refund(uuid,numeric,text) to authenticated;


-- ---------- Secure checkout pricing / payment settings ----------
alter table public.site_settings add column if not exists cod_handling_fee numeric(12,2) not null default 0;
alter table public.site_settings add column if not exists online_payment_discount numeric(12,2) not null default 0;
alter table public.site_settings add column if not exists shipping_fee numeric(12,2) not null default 0;
alter table public.site_settings add column if not exists free_shipping_min numeric(12,2) not null default 0;

create or replace function public.create_checkout_order(
  p_payment_method text,
  p_items jsonb,
  p_address jsonb,
  p_coupon_code text default null,
  p_note text default null
)
returns public.orders
language plpgsql
security definer
set search_path=public
as $$
declare
  v_order public.orders%rowtype;
  v_item jsonb;
  v_product public.products%rowtype;
  v_qty integer;
  v_subtotal numeric(12,2):=0;
  v_discount numeric(12,2):=0;
  v_shipping numeric(12,2):=0;
  v_cod_fee numeric(12,2):=0;
  v_online_discount numeric(12,2):=0;
  v_free_shipping_min numeric(12,2):=0;
  v_total numeric(12,2):=0;
  v_coupon public.coupons%rowtype;
  v_order_id uuid;
  v_order_number text;
  v_stock integer;
  v_line numeric(12,2);
begin
  if auth.uid() is null then raise exception 'Authentication required'; end if;
  if p_payment_method not in ('cod','online') then raise exception 'Invalid payment method'; end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items)=0 then raise exception 'Cart is empty'; end if;
  if coalesce(trim(p_address->>'name'),'')='' or coalesce(trim(p_address->>'phone'),'')='' or coalesce(trim(p_address->>'line1'),'')='' or coalesce(trim(p_address->>'city'),'')='' or coalesce(trim(p_address->>'state'),'')='' or coalesce(trim(p_address->>'pin'),'')='' then raise exception 'Complete delivery address is required'; end if;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty:=greatest(1,least(99,coalesce((v_item->>'quantity')::integer,0)));
    select * into v_product from public.products where id=(v_item->>'product_id')::uuid and published=true for update;
    if not found then raise exception 'A product in your cart is no longer available'; end if;
    v_stock:=coalesce(v_product.stock,0);
    if v_stock < v_qty then raise exception 'Insufficient stock for %',v_product.name; end if;
    v_line:=round(coalesce(v_product.price,0)*v_qty,2);
    v_subtotal:=v_subtotal+v_line;
  end loop;

  if nullif(trim(coalesce(p_coupon_code,'')),'') is not null then
    select * into v_coupon from public.coupons where upper(code)=upper(trim(p_coupon_code)) and enabled=true limit 1;
    if not found then raise exception 'Coupon not found or inactive'; end if;
    if v_coupon.start_at is not null and v_coupon.start_at>now() then raise exception 'Coupon is not active yet'; end if;
    if v_coupon.end_at is not null and v_coupon.end_at<now() then raise exception 'Coupon has expired'; end if;
    if v_coupon.usage_limit is not null and v_coupon.used_count>=v_coupon.usage_limit then raise exception 'Coupon usage limit reached'; end if;
    if v_subtotal < coalesce(v_coupon.min_purchase,0) then raise exception 'Minimum purchase for this coupon is %',v_coupon.min_purchase; end if;
    v_discount:=case when v_coupon.discount_type='percent' then least(v_subtotal,round(v_subtotal*coalesce(v_coupon.discount_value,0)/100,2)) else least(v_subtotal,coalesce(v_coupon.discount_value,0)) end;
  end if;

  select coalesce(shipping_fee,0),coalesce(cod_handling_fee,0),coalesce(online_payment_discount,0),coalesce(free_shipping_min,0)
    into v_shipping,v_cod_fee,v_online_discount,v_free_shipping_min
  from public.site_settings where id=1;
  v_shipping:=coalesce(v_shipping,0); v_cod_fee:=coalesce(v_cod_fee,0); v_online_discount:=coalesce(v_online_discount,0); v_free_shipping_min:=coalesce(v_free_shipping_min,0);
  if v_free_shipping_min>0 and v_subtotal-v_discount>=v_free_shipping_min then v_shipping:=0; end if;
  if p_payment_method='cod' then
    v_total:=greatest(0,v_subtotal-v_discount+v_shipping+v_cod_fee);
  else
    v_discount:=v_discount+least(v_subtotal-v_discount,v_online_discount);
    v_total:=greatest(0,v_subtotal-v_discount+v_shipping);
  end if;

  v_order_number:=public.next_order_number();
  insert into public.orders(user_id,order_number,status,payment_method,payment_status,subtotal,discount,shipping_fee,total,coupon_code,shipping_name,shipping_phone,shipping_line1,shipping_line2,shipping_city,shipping_state,shipping_pincode,customer_note)
  values(auth.uid(),v_order_number,'pending',p_payment_method,'pending',v_subtotal,v_discount,v_shipping,v_total,nullif(trim(p_coupon_code),''),trim(p_address->>'name'),trim(p_address->>'phone'),trim(p_address->>'line1'),nullif(trim(p_address->>'line2'),''),trim(p_address->>'city'),trim(p_address->>'state'),trim(p_address->>'pin'),nullif(trim(coalesce(p_note,'')),''))
  returning * into v_order;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty:=greatest(1,least(99,coalesce((v_item->>'quantity')::integer,0)));
    select * into v_product from public.products where id=(v_item->>'product_id')::uuid for update;
    if coalesce(v_product.stock,0)<v_qty then raise exception 'Stock changed for %; please retry checkout',v_product.name; end if;
    insert into public.order_items(order_id,product_id,product_name,sku,image_url,price,quantity,line_total)
    values(v_order.id,v_product.id,v_product.name,v_product.sku,coalesce(v_product.images->>0,''),v_product.price,v_qty,round(v_product.price*v_qty,2));
    update public.products set stock=coalesce(stock,0)-v_qty where id=v_product.id;
  end loop;
  update public.orders set inventory_reserved=true,confirmed_at=case when p_payment_method='cod' then now() else null end, status=case when p_payment_method='cod' then 'confirmed' else 'pending' end where id=v_order.id returning * into v_order;
  insert into public.order_status_history(order_id,status,note,changed_by) values(v_order.id,v_order.status,'Secure checkout order created',auth.uid());
  if nullif(trim(coalesce(p_coupon_code,'')),'') is not null then
    insert into public.coupon_redemptions(order_id,user_id,code,discount_amount) values(v_order.id,auth.uid(),upper(trim(p_coupon_code)),v_discount);
    update public.coupons set used_count=used_count+1 where upper(code)=upper(trim(p_coupon_code));
  end if;
  return v_order;
exception when others then
  raise;
end; $$;
revoke all on function public.create_checkout_order(text,jsonb,jsonb,text,text) from public;
grant execute on function public.create_checkout_order(text,jsonb,jsonb,text,text) to authenticated;

-- ---------- Coupons ----------
create table if not exists public.coupons (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  discount_type text not null default 'percent',
  discount_value numeric(12,2) not null default 0,
  min_purchase numeric(12,2) not null default 0,
  start_at timestamptz,
  end_at timestamptz,
  usage_limit integer,
  used_count integer not null default 0,
  enabled boolean not null default true,
  product_ids uuid[] default '{}',
  category text,
  created_at timestamptz not null default now()
);
create table if not exists public.coupon_redemptions (
  id uuid primary key default gen_random_uuid(),
  coupon_id uuid references public.coupons(id) on delete set null,
  order_id uuid not null references public.orders(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  code text not null,
  discount_amount numeric(12,2) not null default 0,
  created_at timestamptz not null default now()
);

-- ---------- Loyalty ----------
create table if not exists public.loyalty_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  order_id uuid references public.orders(id) on delete set null,
  points integer not null,
  type text not null,
  note text,
  created_at timestamptz not null default now()
);

-- ---------- Safe order number generator ----------
create sequence if not exists public.madhu_order_seq;
create or replace function public.next_order_number()
returns text language plpgsql security definer set search_path=public
as $$
declare n bigint;
begin
  n:=nextval('public.madhu_order_seq');
  return 'ME-'||to_char(current_date,'YYYYMMDD')||'-'||lpad(n::text,5,'0');
end; $$;
revoke all on function public.next_order_number() from public;
grant execute on function public.next_order_number() to authenticated;

-- ---------- Inventory reservation ----------
create or replace function public.reserve_order_inventory(p_order_id uuid)
returns boolean language plpgsql security definer set search_path=public
as $$
declare item record; updated_rows integer;
begin
  if exists(select 1 from orders where id=p_order_id and inventory_reserved=true) then return true; end if;
  for item in select product_id,quantity from order_items where order_id=p_order_id loop
    if item.product_id is null then continue; end if;
    update products set stock=stock-item.quantity where id=item.product_id and coalesce(stock,0)>=item.quantity;
    get diagnostics updated_rows=row_count;
    if updated_rows<>1 then raise exception 'Insufficient stock for one or more products'; end if;
  end loop;
  update orders set inventory_reserved=true,updated_at=now() where id=p_order_id;
  return true;
end; $$;
revoke all on function public.reserve_order_inventory(uuid) from public;
grant execute on function public.reserve_order_inventory(uuid) to authenticated;

-- ---------- Customer cancellation ----------

create or replace function public.release_reserved_order_inventory(p_order_id uuid)
returns boolean language plpgsql security definer set search_path=public
as $$
declare o orders%rowtype; item record;
begin
  select * into o from public.orders where id=p_order_id for update;
  if not found then raise exception 'Order not found'; end if;
  if not (public.is_admin() or o.user_id=auth.uid()) then raise exception 'Not authorized'; end if;
  if not o.inventory_reserved then return true; end if;
  for item in select product_id,quantity from public.order_items where order_id=o.id loop
    if item.product_id is not null then update public.products set stock=coalesce(stock,0)+item.quantity where id=item.product_id; end if;
  end loop;
  update public.orders set inventory_reserved=false,updated_at=now() where id=o.id;
  return true;
end; $$;
revoke all on function public.release_reserved_order_inventory(uuid) from public;
grant execute on function public.release_reserved_order_inventory(uuid) to authenticated;

create or replace function public.cancel_my_order(p_order_id uuid,p_reason text default 'Customer cancelled')
returns boolean language plpgsql security definer set search_path=public
as $$
declare o orders%rowtype; item record;
begin
  select * into o from orders where id=p_order_id and user_id=auth.uid() for update;
  if not found then raise exception 'Order not found'; end if;
  if o.status not in ('pending','confirmed','processing','packed') then raise exception 'This order can no longer be cancelled'; end if;
  if o.inventory_reserved then
    for item in select product_id,quantity from order_items where order_id=o.id loop
      if item.product_id is not null then update products set stock=coalesce(stock,0)+item.quantity where id=item.product_id; end if;
    end loop;
  end if;
  update orders set status='cancelled',cancelled_at=now(),cancelled_by='customer',cancellation_reason=coalesce(nullif(trim(p_reason),''),'Customer cancelled'),inventory_reserved=false,refund_status=case when payment_method='online' and payment_status in ('paid','captured') then 'requested' else refund_status end,updated_at=now() where id=o.id;
  insert into order_status_history(order_id,status,note,changed_by) values(o.id,'cancelled',coalesce(nullif(trim(p_reason),''),'Customer cancelled'),auth.uid());
  if o.payment_method='online' and o.payment_status in ('paid','captured') then
    insert into refund_requests(order_id,user_id,amount,reason,status) values(o.id,auth.uid(),o.total,coalesce(nullif(trim(p_reason),''),'Customer cancelled'),'requested');
  end if;
  return true;
end; $$;
revoke all on function public.cancel_my_order(uuid,text) from public;
grant execute on function public.cancel_my_order(uuid,text) to authenticated;

-- ---------- Return request ----------
create or replace function public.request_order_return(p_order_id uuid,p_reason text,p_details text default null)
returns uuid language plpgsql security definer set search_path=public
as $$
declare o orders%rowtype; rid uuid;
begin
  select * into o from orders where id=p_order_id and user_id=auth.uid();
  if not found then raise exception 'Order not found'; end if;
  if o.status<>'delivered' then raise exception 'Only delivered orders can be returned'; end if;
  insert into return_requests(order_id,user_id,reason,details) values(o.id,auth.uid(),p_reason,p_details) returning id into rid;
  update orders set status='return_requested',updated_at=now() where id=o.id;
  insert into order_status_history(order_id,status,note,changed_by) values(o.id,'return_requested',p_reason,auth.uid());
  return rid;
end; $$;
revoke all on function public.request_order_return(uuid,text,text) from public;
grant execute on function public.request_order_return(uuid,text,text) to authenticated;

-- ---------- Admin summaries ----------
create or replace function public.get_admin_customer_stats()
returns table(user_id uuid,total_orders bigint,delivered_orders bigint,cancelled_orders bigint,gross_spend numeric,paid_amount numeric,last_order_at timestamptz)
language sql security definer set search_path=public
as $$
select p.id,
 count(o.id),count(o.id) filter(where o.status='delivered'),count(o.id) filter(where o.status='cancelled'),coalesce(sum(o.total) filter(where o.status not in ('cancelled','refunded')),0),coalesce(sum(o.total) filter(where o.payment_status in ('paid','captured')),0),max(o.placed_at)
from profiles p left join orders o on o.user_id=p.id where coalesce(p.role,'customer')<>'admin' group by p.id;
$$;
revoke all on function public.get_admin_customer_stats() from public;
grant execute on function public.get_admin_customer_stats() to authenticated;

create or replace function public.get_admin_order_financial_summary()
returns table(active_orders bigint,delivered_orders bigint,cancelled_orders bigint,order_value numeric,online_paid numeric,cod_value numeric)
language sql security definer set search_path=public
as $$
select count(*) filter(where status not in ('delivered','cancelled','refunded')),
 count(*) filter(where status='delivered'),count(*) filter(where status in ('cancelled','refunded')),
 coalesce(sum(total) filter(where status not in ('cancelled','refunded')),0),
 coalesce(sum(total) filter(where payment_method='online' and payment_status in ('paid','captured')),0),
 coalesce(sum(total) filter(where payment_method='cod'),0) from orders;
$$;
revoke all on function public.get_admin_order_financial_summary() from public;
grant execute on function public.get_admin_order_financial_summary() to authenticated;

-- ---------- RLS ----------
alter table public.orders enable row level security;
alter table public.order_items add column if not exists sku text;
alter table public.order_items enable row level security;
alter table public.payments enable row level security;
alter table public.order_status_history enable row level security;
alter table public.return_requests enable row level security;
alter table public.refund_requests enable row level security;
alter table public.loyalty_ledger enable row level security;

-- Drop/recreate only our Phase 3 policies; this is safe and does not delete data.
drop policy if exists "customer orders read own" on public.orders;
drop policy if exists "customer orders insert own" on public.orders;
drop policy if exists "customer orders update own limited" on public.orders;
drop policy if exists "admin orders all" on public.orders;
create policy "customer orders read own" on public.orders for select to authenticated using(user_id=auth.uid() or public.is_admin());
create policy "customer orders insert own" on public.orders for insert to authenticated with check(user_id=auth.uid());
create policy "customer orders update own limited" on public.orders for update to authenticated using(user_id=auth.uid() or public.is_admin()) with check(user_id=auth.uid() or public.is_admin());
create policy "admin orders all" on public.orders for all to authenticated using(public.is_admin()) with check(public.is_admin());

drop policy if exists "customer order items read own" on public.order_items;
drop policy if exists "customer order items insert own" on public.order_items;
drop policy if exists "admin order items all" on public.order_items;
create policy "customer order items read own" on public.order_items for select to authenticated using(exists(select 1 from orders o where o.id=order_id and (o.user_id=auth.uid() or public.is_admin())));
create policy "customer order items insert own" on public.order_items for insert to authenticated with check(exists(select 1 from orders o where o.id=order_id and o.user_id=auth.uid()));
create policy "admin order items all" on public.order_items for all to authenticated using(public.is_admin()) with check(public.is_admin());

drop policy if exists "customer payments read own" on public.payments;
drop policy if exists "admin payments all" on public.payments;
create policy "customer payments read own" on public.payments for select to authenticated using(user_id=auth.uid() or public.is_admin());
create policy "admin payments all" on public.payments for all to authenticated using(public.is_admin()) with check(public.is_admin());

drop policy if exists "customer history read own" on public.order_status_history;
drop policy if exists "admin history all" on public.order_status_history;
create policy "customer history read own" on public.order_status_history for select to authenticated using(exists(select 1 from orders o where o.id=order_id and (o.user_id=auth.uid() or public.is_admin())));
create policy "admin history all" on public.order_status_history for all to authenticated using(public.is_admin()) with check(public.is_admin());

drop policy if exists "customer returns own" on public.return_requests;
drop policy if exists "admin returns all" on public.return_requests;
create policy "customer returns own" on public.return_requests for all to authenticated using(user_id=auth.uid() or public.is_admin()) with check(user_id=auth.uid() or public.is_admin());
create policy "admin returns all" on public.return_requests for all to authenticated using(public.is_admin()) with check(public.is_admin());

drop policy if exists "customer refunds own" on public.refund_requests;
drop policy if exists "admin refunds all" on public.refund_requests;
create policy "customer refunds own" on public.refund_requests for select to authenticated using(user_id=auth.uid() or public.is_admin());
create policy "admin refunds all" on public.refund_requests for all to authenticated using(public.is_admin()) with check(public.is_admin());

drop policy if exists "customer loyalty own" on public.loyalty_ledger;
drop policy if exists "admin loyalty all" on public.loyalty_ledger;
create policy "customer loyalty own" on public.loyalty_ledger for select to authenticated using(user_id=auth.uid() or public.is_admin());
create policy "admin loyalty all" on public.loyalty_ledger for all to authenticated using(public.is_admin()) with check(public.is_admin());

-- Coupon read is required by checkout; writes remain admin-only through existing policies.
alter table public.coupons enable row level security;
drop policy if exists "customers can read active coupons" on public.coupons;
create policy "customers can read active coupons" on public.coupons for select to authenticated using(enabled=true);

-- Initial order history rows for existing orders.
insert into public.order_status_history(order_id,status,note)
select o.id,o.status,'Initial status imported by Phase 3 migration'
from public.orders o
where not exists(select 1 from public.order_status_history h where h.order_id=o.id);

-- Updated-at helper.
create or replace function public.touch_order_updated_at()
returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end; $$;
drop trigger if exists trg_orders_updated_at on public.orders;
create trigger trg_orders_updated_at before update on public.orders for each row execute function public.touch_order_updated_at();

-- ---------- Admin order state machine ----------
create or replace function public.admin_set_order_status(p_order_id uuid,p_status text,p_reason text default null,p_tracking text default null,p_carrier text default null)
returns boolean language plpgsql security definer set search_path=public
as $$
declare o orders%rowtype; item record;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  select * into o from orders where id=p_order_id for update;
  if not found then raise exception 'Order not found'; end if;
  if p_status not in ('pending','confirmed','processing','packed','shipped','out_for_delivery','delivered','cancelled','return_requested','returned','refunded') then raise exception 'Invalid order status'; end if;
  if p_status='cancelled' and o.status not in ('delivered','cancelled','refunded','returned') and o.inventory_reserved then
    for item in select product_id,quantity from order_items where order_id=o.id loop
      if item.product_id is not null then update products set stock=coalesce(stock,0)+item.quantity where id=item.product_id; end if;
    end loop;
  end if;
  update orders set status=p_status,
    tracking_number=coalesce(nullif(p_tracking,''),tracking_number),
    carrier=coalesce(nullif(p_carrier,''),carrier),
    cancellation_reason=case when p_status='cancelled' then coalesce(nullif(p_reason,''),'Cancelled by admin') else cancellation_reason end,
    cancelled_by=case when p_status='cancelled' then 'admin' else cancelled_by end,
    cancelled_at=case when p_status='cancelled' then coalesce(cancelled_at,now()) else cancelled_at end,
    confirmed_at=case when p_status='confirmed' then coalesce(confirmed_at,now()) else confirmed_at end,
    packed_at=case when p_status='packed' then coalesce(packed_at,now()) else packed_at end,
    shipped_at=case when p_status='shipped' then coalesce(shipped_at,now()) else shipped_at end,
    out_for_delivery_at=case when p_status='out_for_delivery' then coalesce(out_for_delivery_at,now()) else out_for_delivery_at end,
    delivered_at=case when p_status='delivered' then coalesce(delivered_at,now()) else delivered_at end,
    inventory_reserved=case when p_status='cancelled' then false else inventory_reserved end,
    updated_at=now()
  where id=o.id;
  insert into order_status_history(order_id,status,note,changed_by) values(o.id,p_status,coalesce(p_reason,'Updated by admin'),auth.uid());
  return true;
end; $$;
revoke all on function public.admin_set_order_status(uuid,text,text,text,text) from public;
grant execute on function public.admin_set_order_status(uuid,text,text,text,text) to authenticated;

-- ---------- Robust order read APIs ----------
-- These security-definer read functions avoid relying on PostgREST relationship discovery
-- between orders and profiles, and return the complete order package needed by the UI.
create or replace function public.get_my_orders_full()
returns setof jsonb
language sql security definer set search_path=public
as $$
  select jsonb_build_object(
    'order', to_jsonb(o),
    'customer', jsonb_build_object('name',coalesce(p.name,u.raw_user_meta_data->>'name','Customer'),'email',u.email,'phone',coalesce(p.phone,o.shipping_phone)),
    'items', coalesce((select jsonb_agg(to_jsonb(oi) order by oi.created_at) from public.order_items oi where oi.order_id=o.id),'[]'::jsonb),
    'history', coalesce((select jsonb_agg(to_jsonb(h) order by h.created_at) from public.order_status_history h where h.order_id=o.id),'[]'::jsonb),
    'returns', coalesce((select jsonb_agg(to_jsonb(rr) order by rr.created_at desc) from public.return_requests rr where rr.order_id=o.id),'[]'::jsonb)
  )
  from public.orders o
  left join public.profiles p on p.id=o.user_id
  left join auth.users u on u.id=o.user_id
  where o.user_id=auth.uid()
  order by o.placed_at desc;
$$;
revoke all on function public.get_my_orders_full() from public;
grant execute on function public.get_my_orders_full() to authenticated;

create or replace function public.get_admin_orders_full()
returns setof jsonb
language plpgsql security definer set search_path=public
as $$
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  return query
  select jsonb_build_object(
    'order', to_jsonb(o),
    'customer', jsonb_build_object('name',coalesce(p.name,u.raw_user_meta_data->>'name',o.shipping_name,'Customer'),'email',u.email,'phone',coalesce(p.phone,o.shipping_phone)),
    'items', coalesce((select jsonb_agg(to_jsonb(oi) order by oi.created_at) from public.order_items oi where oi.order_id=o.id),'[]'::jsonb),
    'history', coalesce((select jsonb_agg(to_jsonb(h) order by h.created_at) from public.order_status_history h where h.order_id=o.id),'[]'::jsonb),
    'returns', coalesce((select jsonb_agg(to_jsonb(rr) order by rr.created_at desc) from public.return_requests rr where rr.order_id=o.id),'[]'::jsonb),
    'refunds', coalesce((select jsonb_agg(to_jsonb(fr) order by fr.created_at desc) from public.refund_requests fr where fr.order_id=o.id),'[]'::jsonb)
  )
  from public.orders o
  left join public.profiles p on p.id=o.user_id
  left join auth.users u on u.id=o.user_id
  order by o.placed_at desc;
end; $$;
revoke all on function public.get_admin_orders_full() from public;
grant execute on function public.get_admin_orders_full() to authenticated;

-- Make customer cancellation safe and inventory-aware; the frontend must call this RPC.
-- Existing function above remains the canonical cancellation path.


-- ============================================================
-- FINAL V3: secure invoice + admin auth/customer activity
-- ============================================================

create or replace function public.get_order_invoice(p_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
declare r jsonb;
begin
  if not (exists(select 1 from public.orders o where o.id=p_order_id and (o.user_id=auth.uid() or public.is_admin()))) then
    raise exception 'Order not found or access denied';
  end if;
  select jsonb_build_object(
    'order', to_jsonb(o),
    'customer', jsonb_build_object('name',coalesce(p.name,u.raw_user_meta_data->>'name',o.shipping_name,'Customer'),'email',u.email,'phone',coalesce(p.phone,o.shipping_phone)),
    'items', coalesce((select jsonb_agg(to_jsonb(oi) order by oi.created_at) from public.order_items oi where oi.order_id=o.id),'[]'::jsonb)
  ) into r
  from public.orders o
  left join public.profiles p on p.id=o.user_id
  left join auth.users u on u.id=o.user_id
  where o.id=p_order_id;
  return r;
end;
$$;
revoke all on function public.get_order_invoice(uuid) from public;
grant execute on function public.get_order_invoice(uuid) to authenticated;

create or replace function public.get_admin_login_activity()
returns table(
  user_id uuid,
  email text,
  name text,
  phone text,
  created_at timestamptz,
  last_login_at timestamptz,
  provider text,
  action text,
  event_at timestamptz,
  ip_address text
)
language sql
security definer
set search_path = public, auth
as $$
  select
    u.id,
    u.email::text,
    coalesce(p.name,u.raw_user_meta_data->>'name','Customer')::text,
    coalesce(p.phone,u.phone)::text,
    u.created_at,
    u.last_sign_in_at,
    coalesce((u.raw_app_meta_data->>'provider'),'email')::text,
    coalesce(a.action,'user_signup')::text,
    coalesce(a.created_at,u.last_sign_in_at,u.created_at),
    a.ip_address::text
  from auth.users u
  left join public.profiles p on p.id=u.id
  left join lateral (
    select
      x.payload->>'action' as action,
      x.created_at,
      coalesce(x.payload->>'ip_address', x.ip_address::text) as ip_address
    from auth.audit_log_entries x
    where (x.payload->>'user_id') = u.id::text
      and x.payload->>'action' in ('login','user_signedup','logout','user_recovery_requested','user_confirmation_requested')
    order by x.created_at desc limit 1
  ) a on true
  where public.is_admin()
  order by coalesce(a.created_at,u.last_sign_in_at,u.created_at) desc;
$$;
revoke all on function public.get_admin_login_activity() from public;
grant execute on function public.get_admin_login_activity() to authenticated;



-- ============================================================
-- FINAL MASTER: production auth/profile/order/customer fixes
-- Additive and non-destructive. Existing products and orders are preserved.
-- ============================================================

alter table public.profiles add column if not exists name text;
alter table public.profiles add column if not exists phone text;
alter table public.profiles add column if not exists role text default 'customer';
alter table public.profiles add column if not exists avatar_url text;
alter table public.profiles add column if not exists last_login_at timestamptz;

-- Keep a profile row in sync for email, Google and phone-auth users.
create or replace function public.handle_new_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles(id,name,phone,role)
  values(new.id,coalesce(new.raw_user_meta_data->>'name','Customer'),new.phone,'customer')
  on conflict (id) do update set
    name=coalesce(nullif(public.profiles.name,''),excluded.name),
    phone=coalesce(nullif(public.profiles.phone,''),excluded.phone);
  return new;
end;
$$;
drop trigger if exists on_auth_user_created_profile on auth.users;
create trigger on_auth_user_created_profile
after insert on auth.users
for each row execute function public.handle_new_user_profile();

-- Admins can read customer profiles through authenticated RPC/UI without exposing auth.users to customers.
create or replace function public.get_admin_customers_full()
returns setof jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  return query
  select jsonb_build_object(
    'profile', to_jsonb(p),
    'email', u.email,
    'created_at', u.created_at,
    'last_sign_in_at', u.last_sign_in_at,
    'provider', coalesce(u.raw_app_meta_data->>'provider','email'),
    'order_count', (select count(*) from public.orders o where o.user_id=p.id),
    'delivered_count', (select count(*) from public.orders o where o.user_id=p.id and o.status='delivered'),
    'cancelled_count', (select count(*) from public.orders o where o.user_id=p.id and o.status in ('cancelled','rejected')),
    'gross_spend', coalesce((select sum(o.total) from public.orders o where o.user_id=p.id and o.status not in ('cancelled','rejected','refunded')),0),
    'last_order_at', (select max(o.placed_at) from public.orders o where o.user_id=p.id)
  )
  from public.profiles p
  join auth.users u on u.id=p.id
  where coalesce(p.role,'customer')<>'admin'
  order by u.created_at desc;
end;
$$;
revoke all on function public.get_admin_customers_full() from public;
grant execute on function public.get_admin_customers_full() to authenticated;

-- Admin return queue with customer details, order details and invoice-safe data.
create or replace function public.get_admin_returns_full()
returns setof jsonb
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  return query
  select jsonb_build_object(
    'return', to_jsonb(rr),
    'order', to_jsonb(o),
    'customer', jsonb_build_object('name',coalesce(p.name,u.raw_user_meta_data->>'name',o.shipping_name,'Customer'),'email',u.email,'phone',coalesce(p.phone,o.shipping_phone))
  )
  from public.return_requests rr
  join public.orders o on o.id=rr.order_id
  left join public.profiles p on p.id=rr.user_id
  left join auth.users u on u.id=rr.user_id
  order by rr.created_at desc
  limit 300;
end;
$$;
revoke all on function public.get_admin_returns_full() from public;
grant execute on function public.get_admin_returns_full() to authenticated;

-- Admin may accept/reject return requests through one secure state-changing RPC.
create or replace function public.admin_update_return(p_return_id uuid,p_status text)
returns boolean
language plpgsql
security definer
set search_path=public
as $$
declare rr return_requests%rowtype;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  if p_status not in ('requested','approved','rejected','received','refunded') then raise exception 'Invalid return status'; end if;
  select * into rr from public.return_requests where id=p_return_id for update;
  if not found then raise exception 'Return request not found'; end if;
  update public.return_requests set status=p_status,updated_at=now() where id=p_return_id;
  if p_status='approved' then
    update public.orders set status='return_requested',updated_at=now() where id=rr.order_id;
  elsif p_status='rejected' then
    update public.orders set status='delivered',updated_at=now() where id=rr.order_id and status='return_requested';
  elsif p_status='received' then
    update public.orders set status='returned',updated_at=now() where id=rr.order_id;
  elsif p_status='refunded' then
    update public.orders set status='refunded',refund_status='refunded',refunded_at=coalesce(refunded_at,now()),updated_at=now() where id=rr.order_id;
  end if;
  insert into public.order_status_history(order_id,status,note,changed_by)
  values(rr.order_id,case when p_status='rejected' then 'delivered' when p_status='received' then 'returned' when p_status='refunded' then 'refunded' else 'return_requested' end,'Return request '+p_status,auth.uid());
  return true;
end;
$$;
revoke all on function public.admin_update_return(uuid,text) from public;
grant execute on function public.admin_update_return(uuid,text) to authenticated;

-- Admin order state machine: rejected is an explicit order-request outcome.
create or replace function public.admin_set_order_status(p_order_id uuid,p_status text,p_reason text default null,p_tracking text default null,p_carrier text default null)
returns boolean language plpgsql security definer set search_path=public
as $$
declare o orders%rowtype; item record;
begin
  if not public.is_admin() then raise exception 'Admin access required'; end if;
  select * into o from orders where id=p_order_id for update;
  if not found then raise exception 'Order not found'; end if;
  if p_status not in ('pending','confirmed','processing','packed','shipped','out_for_delivery','delivered','cancelled','rejected','return_requested','returned','refunded') then raise exception 'Invalid order status'; end if;
  if p_status in ('cancelled','rejected') and o.status not in ('delivered','cancelled','rejected','refunded','returned') and o.inventory_reserved then
    for item in select product_id,quantity from order_items where order_id=o.id loop
      if item.product_id is not null then update products set stock=coalesce(stock,0)+item.quantity where id=item.product_id; end if;
    end loop;
  end if;
  update orders set status=p_status,
    tracking_number=coalesce(nullif(p_tracking,''),tracking_number),
    carrier=coalesce(nullif(p_carrier,''),carrier),
    cancellation_reason=case when p_status in ('cancelled','rejected') then coalesce(nullif(p_reason,''),case when p_status='rejected' then 'Rejected by admin' else 'Cancelled by admin' end) else cancellation_reason end,
    cancelled_by=case when p_status in ('cancelled','rejected') then 'admin' else cancelled_by end,
    cancelled_at=case when p_status in ('cancelled','rejected') then coalesce(cancelled_at,now()) else cancelled_at end,
    confirmed_at=case when p_status='confirmed' then coalesce(confirmed_at,now()) else confirmed_at end,
    packed_at=case when p_status='packed' then coalesce(packed_at,now()) else packed_at end,
    shipped_at=case when p_status='shipped' then coalesce(shipped_at,now()) else shipped_at end,
    out_for_delivery_at=case when p_status='out_for_delivery' then coalesce(out_for_delivery_at,now()) else out_for_delivery_at end,
    delivered_at=case when p_status='delivered' then coalesce(delivered_at,now()) else delivered_at end,
    inventory_reserved=case when p_status in ('cancelled','rejected') then false else inventory_reserved end,
    updated_at=now()
  where id=o.id;
  insert into order_status_history(order_id,status,note,changed_by) values(o.id,p_status,coalesce(p_reason,case when p_status='rejected' then 'Rejected by admin' else 'Updated by admin' end),auth.uid());
  return true;
end; $$;
revoke all on function public.admin_set_order_status(uuid,text,text,text,text) from public;
grant execute on function public.admin_set_order_status(uuid,text,text,text,text) to authenticated;

-- Existing customers without a profile row are backfilled without touching orders/products.
insert into public.profiles(id,name,phone,role)
select u.id,coalesce(u.raw_user_meta_data->>'name','Customer'),u.phone,'customer'
from auth.users u
where not exists(select 1 from public.profiles p where p.id=u.id);

-- Robust audit-log query: Supabase stores event fields in payload JSON.
create or replace function public.get_admin_login_activity()
returns table(user_id uuid,email text,name text,phone text,created_at timestamptz,last_login_at timestamptz,provider text,action text,event_at timestamptz,ip_address text)
language sql security definer set search_path=public,auth
as $$
  select u.id,u.email::text,coalesce(p.name,u.raw_user_meta_data->>'name','Customer')::text,coalesce(p.phone,u.phone)::text,u.created_at,u.last_sign_in_at,coalesce(u.raw_app_meta_data->>'provider','email')::text,
    coalesce(a.action,'user_signup')::text,coalesce(a.event_at,u.last_sign_in_at,u.created_at),a.ip_address::text
  from auth.users u
  left join public.profiles p on p.id=u.id
  left join lateral (
    select x.payload->>'action' as action,x.created_at as event_at,x.payload->>'ip_address' as ip_address
    from auth.audit_log_entries x
    where x.payload->>'user_id'=u.id::text
      and x.payload->>'action' in ('login','user_signedup','logout','user_recovery_requested','user_confirmation_requested')
    order by x.created_at desc limit 1
  ) a on true
  where public.is_admin()
  order by coalesce(a.event_at,u.last_sign_in_at,u.created_at) desc;
$$;
revoke all on function public.get_admin_login_activity() from public;
grant execute on function public.get_admin_login_activity() to authenticated;


-- ---------- Verified customer reviews (final) ----------
-- A review is allowed only when the signed-in customer has an order containing
-- the product and that order has reached Delivered status. Customers cannot
-- insert reviews directly; the security-definer RPC performs the eligibility check.
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  product_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  rating integer not null check(rating between 1 and 5),
  review_text text not null default '',
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.reviews add column if not exists product_id uuid;
alter table public.reviews add column if not exists user_id uuid;
alter table public.reviews add column if not exists rating integer;
alter table public.reviews add column if not exists review_text text;
alter table public.reviews add column if not exists status text not null default 'pending';
alter table public.reviews add column if not exists created_at timestamptz not null default now();
alter table public.reviews add column if not exists updated_at timestamptz not null default now();
create index if not exists reviews_product_status_idx on public.reviews(product_id,status,created_at desc);
create index if not exists reviews_user_idx on public.reviews(user_id,created_at desc);
create unique index if not exists reviews_product_user_uidx on public.reviews(product_id,user_id);

alter table public.reviews enable row level security;
drop policy if exists "reviews public approved" on public.reviews;
drop policy if exists "reviews own read" on public.reviews;
drop policy if exists "reviews admin all" on public.reviews;
create policy "reviews public approved" on public.reviews for select to anon,authenticated using(status='approved' or user_id=auth.uid() or public.is_admin());
create policy "reviews admin all" on public.reviews for all to authenticated using(public.is_admin()) with check(public.is_admin());

revoke insert, update, delete on public.reviews from authenticated;
grant select on public.reviews to anon,authenticated;
grant update, delete on public.reviews to authenticated;

create or replace function public.can_review_product(p_product_id uuid)
returns boolean
language sql
security definer
set search_path=public
as $$
  select exists(
    select 1
    from public.orders o
    join public.order_items oi on oi.order_id=o.id
    where o.user_id=auth.uid()
      and o.status='delivered'
      and oi.product_id=p_product_id
  );
$$;
revoke all on function public.can_review_product(uuid) from public;
grant execute on function public.can_review_product(uuid) to authenticated;

create or replace function public.submit_product_review(p_product_id uuid,p_rating integer,p_review_text text)
returns jsonb
language plpgsql
security definer
set search_path=public
as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Please login to submit a review'; end if;
  if p_rating < 1 or p_rating > 5 then raise exception 'Rating must be between 1 and 5'; end if;
  if length(trim(coalesce(p_review_text,''))) < 3 then raise exception 'Please write a review'; end if;
  if not exists(
    select 1 from public.orders o
    join public.order_items oi on oi.order_id=o.id
    where o.user_id=auth.uid() and o.status='delivered' and oi.product_id=p_product_id
  ) then
    raise exception 'Only customers who received this product can review it';
  end if;
  insert into public.reviews(product_id,user_id,rating,review_text,status,updated_at)
  values(p_product_id,auth.uid(),p_rating,trim(p_review_text),'pending',now())
  on conflict (product_id,user_id) do update set rating=excluded.rating,review_text=excluded.review_text,status='pending',updated_at=now()
  returning id into v_id;
  return jsonb_build_object('id',v_id,'status','pending');
end;
$$;
revoke all on function public.submit_product_review(uuid,integer,text) from public;
grant execute on function public.submit_product_review(uuid,integer,text) to authenticated;
