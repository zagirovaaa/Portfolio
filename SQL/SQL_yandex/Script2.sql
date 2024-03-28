--1. Выведите общую сумму просмотров постов за каждый месяц 2008 года. 
--Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. 
--Результат отсортируйте по убыванию общего количества просмотров.

WITH t AS (
SELECT user_id,
       COUNT(DISTINCT id) AS cnt
FROM stackoverflow.posts
GROUP BY user_id
ORDER BY cnt DESC
LIMIT 1),

     t1 AS (
SELECT p.user_id,
       p.creation_date,
       extract('week' from p.creation_date) AS week_number
FROM stackoverflow.posts AS p
JOIN t ON t.user_id = p.user_id
WHERE DATE_TRUNC('month', p.creation_date)::date = '2008-10-01'
           )

SELECT DISTINCT week_number::numeric,
       MAX(creation_date) OVER (PARTITION BY week_number)
FROM t1
ORDER BY week_number;

--2.Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. 
--Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений user_id. 
--Отсортируйте результат по полю с именами в лексикографическом порядке.
SELECT u.display_name,
        COUNT (DISTINCT p.user_id)
FROM stackoverflow.users AS u
JOIN stackoverflow.posts AS p ON u.id=p.user_id
JOIN stackoverflow.post_types AS pt ON p.post_type_id= pt.id
WHERE (p.creation_date::date BETWEEN u.creation_date::date  AND  u.creation_date::date + INTERVAL '1 month') AND pt.type LIKE'%Answer%'
 GROUP BY u.display_name
 HAVING COUNT(p.id) > 100 
ORDER BY u.display_name;

--3.Выведите количество постов за 2008 год по месяцам. 
--Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года.
--Отсортируйте таблицу по значению месяца по убыванию.
WITH a AS
(SELECT p.user_id
FROM stackoverflow.posts AS p
JOIN stackoverflow.users AS u ON p.user_id= u.id
WHERe DATE_TRUNC ('month', u.creation_date) = '2008-09-01' AND  DATE_TRUNC('month', p.creation_date)::date = '2008-12-01'
GROUP BY p.user_id
HAVING COUNT (p.id) >0)

SELECT COUNT (p.id),
       DATE_TRUNC('month', p.creation_date)::date
FROM  stackoverflow.posts AS p
WHERE p.user_id IN (SELECT * FROM a)
GROUP BY DATE_TRUNC('month', p.creation_date)::date
ORDER BY DATE_TRUNC('month', p.creation_date)::date DESC;

--4.Используя данные о постах, выведите несколько полей:
--идентификатор пользователя, который написал пост;
--дата создания поста;
--количество просмотров у текущего поста;
--сумму просмотров постов автора с накоплением.
--Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.

SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date) AS sum_views
FROM stackoverflow.posts;

--5.Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой?
--Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. 
--Нужно получить одно целое число
WITH a AS
(SELECT COUNT (DISTINCT creation_date::date) AS days,
        COUNT(DISTINCT user_id) AS users
FROM stackoverflow.posts
    WHERE creation_date::date  BETWEEN '2008-12-01'  AND '2008-12-07'
GROUP BY user_id
HAVING COUNT(id)>0)

SELECT ROUND (SUM(days)/SUM(users))
FROM a;

--6.На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
--номер месяца;
--количество постов за месяц;
--процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
--Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. 
--Округлите значение процента до двух знаков после запятой.
WITH tabl AS
(SELECT EXTRACT (MONTH FROM creation_date::date) AS month,
       COUNT(DISTINCT id) AS post
FROM stackoverflow.posts
WHERE creation_date::date BETWEEN '2008-09-01' AND '2008-12-31'
GROUP BY  EXTRACT (MONTH FROM creation_date::date))

SELECT *,
       ROUND(((post::numeric / LAG(post) OVER (ORDER BY month)) - 1) * 100,2) AS change
FROM tabl;

--7.Выгрузите данные активности пользователя, который опубликовал больше всего постов за всё время. 
--Выведите данные за октябрь 2008 года в таком виде:
--номер недели;
--дата и время последнего поста, опубликованного на этой неделе.
WITH t AS (
SELECT user_id,
       COUNT(DISTINCT id) AS cnt
FROM stackoverflow.posts
GROUP BY user_id
ORDER BY cnt DESC
LIMIT 1),

     t1 AS (
SELECT p.user_id,
       p.creation_date,
       extract('week' from p.creation_date) AS week_number
FROM stackoverflow.posts AS p
JOIN t ON t.user_id = p.user_id
WHERE DATE_TRUNC('month', p.creation_date)::date = '2008-10-01'
           )

SELECT DISTINCT week_number::numeric,
       MAX(creation_date) OVER (PARTITION BY week_number)
FROM t1
ORDER BY week_number;
