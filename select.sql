select payment_ud, amount
from payments
where city='Москва'
order by amount desc
limit 2


select category,sum(amount)
from transfers
where amount>100
group by category
having sum(amount)>=1000


select c.client_name
from clients c
left join orders o on c.client_id=o.client_id
where status = 'NULL'


select c.client_name, sum(case when o.status='delivered' then o.total else 0 end)
from clients c
left join orders o on c.client_id=o.client_id
group by c.client_name


select c.courier_name
from couriers c
join left deliveries d on c.courier_id=d.courier_id
where d.delivery_id IS NULL


select c.courier_name< sum(case when d.status='complited' then d.fee else 0 end) as sum_courier
from couriers c
join left deliveries d on c.courier_id=d.courier_id
group by c.courier_name


select plan, sum(price)
from subscriptions
where status='paid'
group by plan
having sum(price)>=500

select u.user_name
from users u
left join subscriptions s on u.user_id=s.user_id
where u.city= 'Москва' and sub_id is NULL

select u.user_name, sum(case when s.status='paid' then price else 0 end) as total_paid
from users u
left join subscriptions s on u.user_id=s.user_id
group by u.user_name
order by total_paid desc
limit 3
with user_sums as (
    select user_id, sum(price) as total_price
    from subscriptions
    where status='paid'
    group by user_id
)
select user_id, count(*)
from user_sums
where total_price>=500

with ranked_sales as(
    select sale_id,
    dept,
    manager,
    dense_rank() over(partition by dept order by revenue desc) as hui
    from sales
)
select sale_id, dept, manager, dense_rank() over(partition by dept order by revenue desc) as hui
from ranked_sales
where hui<=2


select deal_id, seller_id, amount, avg(amount) over(partition by seller_id) as seller_avg
from deals
where status='completed'


with table as(
    select seller_id, deal_id, amount, row_number() over(partition by seller_id order by amount) as rn
    from deals
    where status='completed'
)
select seller_id, deal_id, amount
from table
where rn=1

with table as(
    select region,
    seller_name,
    sum(amount) as total_rev
    from sellers s
    left join deals d on s.seller_id=d.seller_id and status='completed'
    group by s.seller_name
)
select region, seller_name, total_rev,sddsf,
dense_rank() over(partition by region order by total_rev desc) as rnk
from table
order by region, rnk desc




SELECT
    tx_id,
    rub_amount,
    LAG(rub_amount, 1, 0) OVER (PARTITION BY investor_id ORDER BY tx_day) AS col_a,
    SUM(rub_amount) OVER (PARTITION BY investor_id ORDER BY tx_day) AS col_b,
    SUM(rub_amount) OVER (PARTITION BY investor_id) AS col_c
FROM transactions
WHERE investor_id = 1 AND tx_type = 'deposit';

1:
1 1000 0 1000 7500
2 2500 1000 3500 7500
4 4000 2500 7500 7500


2:
select investor_id, tx_day, rub_amount,
    lag(rub_amount) over(partition by investor_id order by tx_day) as prev_amount,
    rub_amount-lag(rub_amount) over(partition by investor_id order by tx_day) as delta
from transactions
where tx_type='deposit'

3:
with t as(
SELECT investor_id, tx_id, tx_day, rub_amount,
    row_number() over(partition by investor_id order by tx_day) as rn
    from transactions
    where tx_type='deposit'
)
SELECT investor_id, tx_id, tx_day, rub_amount
from t
where rn=1


4:
with t as(
select investor_id, tx_id, tx_day, rub_amount,
    sum(rub_amount) over(partition by investor_id order by tx_day) as running_deposit
    from transactions
    where tx_type='deposit'
)
select investor_id, tx_id, tx_day, rub_amount, running_deposit
from t
where running_deposit>=3500

5:
1)
with t as(
    select i.investor_id, i.tariff, i.full_name,
    sum(case when tx_type='deposit' then rub_amount else 0 end) as total_deposit
    from investors i
    left join transactions t on i.investor_id=t.investor_id
    group by i.investor_id, i.tariff, i.full_name
)
select tariff, full_name, total_deposit,
dense_rank() over(partition by tariff order by total_deposit desc) as rnk
from t


2)
select i.tariff, i.full_name,
coalesce(sum(t.amount),0) as total_deposit,
dense_rank() over(partition by tariff order by coalesce(sum(t.amount),0) desc) as rnk
from investors i
left join transactions t on i.investor_id=t.investor_id and t.tx_type='deposit'
group by i.investor_id, i.tariff, i.full_name
order by tariff,rnk

7 4 87,5 5 2000

select u.user_id, u.user_name
from users u
left join cards c on u.user_id-c.user_id
left join operations o on c.card_id=o.card_id and status='ok'
where u.city='Москва'
group by u.user_id, u.user_name
having count(o.card_id)=0
4 лебедев

select category, count(status)as ok_cnt,
sum(amount) as total_amount,
coalesce(sum(cashback,0)) as total_cashback
from operations
where status='ok'
group by category
having count(status)>=2
order by total_amount desc


select u.city, u.user_id, u.user_name,
coalesce(sum(amount),0) as total_spent,
dense_rank() over(partition by u.city order by coalesce(sum(amount),0) desc) as rnk
from users u
left join cards c on u.user_id=c.user_id
left join operations o on c.card_id=o.card_id and status='ok'
group by u.city, u.user_id, u.user_name
order by city, rnk


select o.op_id, o.op_day, o.amount,
LAG(o.amount,1,0) over (order by op_day, op_id) as prev_amount,
amount-LAG(o.amount,1,0) over (order by op_day, op_id) as diff
from cards c
inner join operations o on c.card_id=o.card_id and status='ok'
where c.user_id=1


with t as(
select u.user_id, op_id, op_day, amount,
sum(amount) over (partition by u.user_id order by op_day, op_id) as running_total
from users u
join cards c on u.user_id=c.user_id
join operation o on c.card_id=o.card_id
where status='ok'
),t2 as(
    select user_id, op_id, op_day, amount, running_total,
    row_number() over (partition by user_id order by op_day,op_id ) as rn
     from t
     where running_total>=5000
)
select user_id, op_id, op_day, amount, running_total
from t2
where rn=1




select count(case when status='ok' then 1 else 0 end)as ok_ops_cnt,
sum(case when status='fail' then 1 else 0 end) as fail_ops_cnt,
coalesce(sum(case when status='ok' then cashback),0)as ok_cashback_sum
from operations

select u.city, u.user_id, u.user_name,
coalesce(sum(amount),0) as total_spent,
dense_rank() over(partition by u.city order by coalesce(sum(amount),0) desc) as rnk
from users u
left join cards c on u.user_id=c.user_id
left join operations o on c.card_id=o.card_id and status='ok'
group by u.city, u.user_id, u.user_name
order by city, rnk

POST, нет не является, запрос обратботается и будет повторное списание, сппециальный ключ idempotency_key который при первом запросе запсиывается бд и если приходть повторный запрос с таким же клбчом то сервер дает такой же ответ как и в начале

401 403 400 500
{
  "user_id": 104,
  "user_name": "Лебедев",
  "is_active": true,
  "cards": [10, 20 ],
  "credit_limit": null
}

CR=45%  R7=25% ARPU=300 ARPPU=1500


select count(case when status='ok' and amount>1000 then 1 end)as big_ok_cnt,
coalesce(sum(case when status='ok' then amount else 0 end),0) as ok_total
from operations
1 2000
0 потому что там будет проверяться по правилам конъюнкции и поулчится так что по 1 услвоию он проходит а по вторму там null и система не знает что ответить и выдает null
select user_id
from users
where user_id not in (select user_id from blacklist where user_id is not null)

если через union то будет 5 строки 10 20 20 20 30
если через union all то будет 3 строки 10 20 30

это M:N, user_subscriptions(user_id, sub_id) это PK ну и по отдельности они наверное внешние ключи вот этот момент я не пнял немного конечно

шаг 2 нужно послать запрос в антифрод сначала потом в бд потом долден отправить асинхронный запрос во внешний шлюз и не дожидаясь овтета выдать клиенту 200 ок

fr nfr nfr fr


select client_id, client_name
from clients
where not exists(select 1 from archive_clients)
1 иванов 3 сидоров

union 3 строки и раюоатет дольше потмоу что идет сортирвока по дублкиатам а union all 4 строки

select date_trunc('month', paid_at) as pay_month, sum(amount) as monthly_sum
from payments
group by date_trunc('month', paid_at)
having sum(amount)>100000
order by pay_month

а все круто б оштбка первичного ключа потому что повтор его иендт а в ошибка внешнего ключа

1 запустит одну любую 2 процес никогда н дойдет до конца потому что будет ждать ответ от 2 других процессов нужно в начале поставить and и запустить синхронную проверку

99, 189
48%

select c.client_id, c.client_name,
coalesce(sum( t.amount),0) as total_ok_amount
from clients c
left join accounts a on c.client_id=a.client_id
left join transfers t on a.acc_id=t.acc_id and t.status='ok'
where c.segment='Premium' and not exists (select 1 from blacklist b where c.client_id=b.client_id)
group by c.client_id, c.client_name
order by total_ok_amount desc
1 соколов 11000 4 зайцева 0

select date_trunc('month', tr_date) as tr_month,
count(case when status='ok' then 1 end)as ok_cnt,
sum(case when status='fail' then 1 else 0 end) as fail_cnt,
coalesce(sum(case when status='ok' then fee end),0) as ok_fee_sum
from transfers
group by date_trunc('month', tr_date)
order by tr_month

select t.tr_id, t.amount, lag(amount,1,0) over(order by tr_date, tr_id)  as prev_amount,
amount-lag(amount,1,0) over(order by t.tr_date, t.tr_id)  as diff
from transfers t
join accounts a on t.acc_id=a.acc_id
where t.status='ok' and a.client_id=1

with t as(
    select a.client_id, t.tr_id, t.amount,
    sum(amount) over(partition by a.client_id order by tr_date, tr_id) as running_total
    from transfers t
    join accounts a on t.acc_id=a.acc_id and t.status='ok'
), t2 as(
select client_id, tr_id, amount,
row_number() over(partition by client_id order by tr_date, tr_id) as rn
from t
where running_total>=6000
)
select client_id, tr_id, amount, running_total
from t2
where rn=1
order by client_id

8 пр union all(12331123) и 4 при union(1234)

M:N clients_categories(client_id,cat_id) PK(client_id,cat_id) FK(client_id)(cat_id)
1 это ошибка пвричного ключа так как илдет повторение,2 это ошибка вншенего ключа так ка он хочет присоеденить того чего нет

POST и присваивается специальный код который бд записыывает при первом вызвое и при послежующих вызовах он читает этот ключ и возваращет операцию на то же место что и было хоть сколько  запрсоов придет
"currency": "RUB",
"auto_refill": false,
"initial_amounts": [1000, 1500 ],
401 403 400 504

сначала должан быть првоерка а потом сообщение в бд, нуден асинхронный вызов с помощью брокера kafka не дожидаясь ответа от сервиса генерации выдать 200 клиенту, проверка документов
задача 0,2,3 всего 3, все правильно
fr nfr fr nfr

неплательщики:450  надежные клиенты:950 всего:1350 33%

with t as(
select client_id, transaction_date,
coalesce(transaction_date-lag(transaction_date)
over(partition by client_id order by transaction_date),0) as days_since_prev
from transactions
)
select client_id, transation_date, days_since_prev
from t
where days_since_prev>30
order by client_id, transaction_date


with t as(
select transfer_id, transfer_date, amount,
dense_rank() over(partition by transfer_date order by amount desc) as dense_rank,
sum(amount) over(partition by transfer_date order by amount desc, transfer_id) as r unning_day_sum
from transfers
)
select transfer_id, transfer_date, amount, dense_rank, running_day_sum
from t
where dense_rank <=2
order by transfer_date desc, amount desc

with t as(
select user_id, order_time
row_number() over(partition by user_id order by order_time, order_id) as rn
lead(order_time) over(partition by user_id order by order_time, order_id) as next_order_time
from orders
where status='success'
)
select date_trunc('month', order_time) as cohort_month,
count(*) as total_users,
count(case when next_order_time <= order_time + interval '30 days' then 1 end) as retained_users,
round(count(case when next_order_time <= order_time + interval '30 days' then 1 end)::numeric/count(*), 2) as conversion_rate
from t
where rn=1
group by cohort_month
order by cohort_month
    