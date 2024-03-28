--1. Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».

SELECT count (*)
FROM stackoverflow.posts
WHERE post_type_id  = 1 AND (score > 300 OR favorites_count >=100);

--2.Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.

WITH p AS 
(SELECT count (post_type_id) AS kol
FROM stackoverflow.posts
WHERE post_type_id  = 1 AND ( creation_date::date BETWEEN '2008-11-01' AND '2008-11-18') )

SELECT ROUND(AVG(kol)/18)
FROM p;

--3.Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.

SELECT COUNT( DISTINCT u.id)
FROM stackoverflow.users AS u 
INNER JOIN stackoverflow.badges AS b ON u.id = b.user_id
WHERE u.creation_date::date = b.creation_date::date;

--4.Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?

SELECT COUNT (DISTINCT p.id)
FROM stackoverflow.posts AS p
JOIN stackoverflow.votes AS v ON p.id = v.post_id
JOIN stackoverflow.users AS u ON p.user_id = u.id
WHERE u.display_name LIKE 'Joel Coehoorn' AND v.id >=1;

--5.Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id.

SELECT *,
        ROW_NUMBER() OVER(ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types
ORDER BY id;

--6. Отберите 10 пользователей, которые поставили больше всего голосов типа Close. Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов.
--Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.

SELECT *
FROM (
      SELECT v.user_id,
             COUNT(v.id) AS cnt
      FROM stackoverflow.votes AS v
        WHERE vote_type_id=6
      GROUP BY v.user_id
      ORDER BY cnt DESC LIMIT 10
    ) AS t
ORDER BY t.cnt DESC, t.user_id DESC;

--7. Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
--Отобразите несколько полей:
--идентификатор пользователя;
--число значков;
--место в рейтинге — чем больше значков, тем выше рейтинг.
--Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
--Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.

SELECT *,
    DENSE_RANK() OVER(ORDER BY  t.cnt DESC)
FROM (
      SELECT b.user_id,
            COUNT(b.id) AS cnt
      FROM stackoverflow.badges AS b
      WHERE creation_date::date BETWEEN '2008-11-15' AND '2008-12-15'
      GROUP BY b.user_id
      ORDER BY cnt DESC LIMIT 10
    ) AS t

    ORDER BY t.cnt DESC, t.user_id;
   
--8. Сколько в среднем очков получает пост каждого пользователя?
--Сформируйте таблицу из следующих полей:
--заголовок поста;
--идентификатор пользователя;
--число очков поста;
--среднее число очков пользователя за пост, округлённое до целого числа.
--Не учитывайте посты без заголовка, а также те, что набрали ноль очков.

SELECT title,
        user_id,
        score,
        ROUND(AVG(score) OVER (PARTITION BY   user_id) )AS avg_score
FROM stackoverflow.posts
WHERE title IS NOT NULL AND score!=0
ORDER BY user_id;

--9.Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. 
--Посты без заголовков не должны попасть в список.

WITH t AS 
(SELECT b.user_id
FROM stackoverflow.badges AS b
GROUP BY b.user_id
HAVING COUNT (b.id) > 1000) 

SELECT p.title
FROM   stackoverflow.posts AS p
LEFT JOIN   stackoverflow.users AS u ON p.user_id=u.id
JOIN t ON u.id= t.user_id
WHERE title IS NOT NULL;

--10.Напишите запрос, который выгрузит данные о пользователях из США (англ. United States). Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
--пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
--пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
--пользователям с числом просмотров меньше 100 — группу 3.
--Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. 
--Пользователи с нулевым количеством просмотров не должны войти в итоговую таблицу.

SELECT DISTINCT u.id,
       u.views,
      CASE 
        WHEN u.views >=350 THEN 1
        WHEN u.views >=100 THEN 2
        WHEN u.views < 100 THEN 3
    END AS category
FROM stackoverflow.users AS u
WHERE u.location LIKE '%United States%' AND
views !=0;

--11.Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. 
--Выведите поля с идентификатором пользователя, группой и количеством просмотров.
--Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.

WITH t AS 
(SELECT DISTINCT u.id,
       u.views,
      CASE 
        WHEN u.views >=350 THEN 1
        WHEN u.views >=100 THEN 2
        WHEN u.views < 100 THEN 3
    END AS category
FROM stackoverflow.users AS u
WHERE u.location LIKE '%United States%' AND
views !=0),
maximum AS (
SELECT *,
       MAX(views) OVER (PARTITION BY t.category) AS maxi
FROM t )

SELECT maximum.id,
    maximum.category,
    maximum.maxi
FROM maximum 
WHERE maximum.views = maximum.maxi
ORDER BY maximum.maxi DESC, maximum.id;

--12.Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
--номер дня;
--число пользователей, зарегистрированных в этот день;
--сумму пользователей с накоплением.

WITH t AS (
SELECT EXTRACT(DAY FROM creation_date::date) AS days,
       count(id) AS total_user
FROM stackoverflow.users
WHERE creation_date::date BETWEEN '2008-11-01' AND '2008-11-30'
GROUP BY EXTRACT(DAY FROM creation_date::date))

SELECT *,
    SUM(total_user) OVER (ORDER BY days)
FROM t;

--13. Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите:
--идентификатор пользователя;
--разницу во времени между регистрацией и первым постом.

WITH p AS
(SELECT DISTINCT user_id,
        MIN(creation_date) OVER (PARTITION BY user_id) AS min_dt					
 FROM stackoverflow.posts
)

SELECT p.user_id,
       (p.min_dt - u.creation_date) AS diff
FROM stackoverflow.users AS u 
JOIN p ON  u.id = p.user_id;
