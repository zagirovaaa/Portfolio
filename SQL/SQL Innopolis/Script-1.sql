/* 1 Вывести название, описание и длительность фильмов, выпущенных после
2000-ого года. Включить только фильмы длительностью в интервале от 60
до 120 минут (включ.). Показать первые 20 фильмов по длительности
(самые длинные).
 */
SELECT title, description, length
FROM film 
WHERE release_year > 2000 AND length BETWEEN 60 AND 120
ORDER BY length DESC 
LIMIT 20;


/*2. Найти все платежи, совершенные в апреле 2007-го года, чья стоимость не
превышает 4 долларов. Показать идентификатор, дату (без времени), и
стоимость платежа. Платежи отобразить в порядке убывания стоимости.
При совпадении стоимости, отдать предпочтение более раннему платежу.
*/
SELECT payment_id, DATE(payment_date), amount
FROM payment 
WHERE DATE (payment_date) BETWEEN '2007-04-01' AND '2007-04-30' AND amount <= 4  
ORDER BY amount DESC, payment_date;

/*3. Показать имена, фамилии и идентификаторы всех клиентов с именами
“Jack”, “Bob”, или “Sara”, чья фамилия содержит букву “p”. Переименовать
колонку с именем в “Имя”, с идентификатором в “Идентификатор”, с
фамилией в “Фамилия”. Клиентов отобразить в порядке возрастания их
идентификатора.*/
SELECT first_name AS "Имя",
	   last_name AS "Фамилия",
	   customer_id AS "Идентификатор"
FROM customer
WHERE first_name IN ('Jack', 'Bob', 'Sara') AND last_name ILIKE '%p%'
ORDER BY customer_id;

/*4. Посчитать выручку в каждом месяце работы проката. Месяц должен
рассчитываться по rental_date, а не по payment_date. Округлить выручку до
одного знака после запятой. Отсортировать строки в хронологическом
порядке.
Подсказка: есть месяц проката, где выручки не было (нет данных о
платежах) - он должен присутствовать в отчете.
*/
SELECT EXTRACT(YEAR FROM rental_date),
	   EXTRACT(MONTH FROM rental_date),
	   ROUND(SUM(p.amount),1)
FROM rental r
LEFT JOIN payment p ON r.rental_id=p.rental_id 
GROUP BY 1,2
ORDER BY 1,2;

/*5. Найти средний платеж по каждому жанру фильма. Отобразить только те
жанры, к которым относится более 60 различных фильмов. Округлить
средний платеж до двух знаков после запятой. Дать названия столбцам.
Отобразить жанры в порядке убывания среднего платежа.*/
SELECT c.name AS "Жанр",
		ROUND(AVG(amount),2) AS "Средний платеж",
FROM film_category fc
LEFT JOIN category c ON fc.category_id=c.category_id
LEFT JOIN film f ON fc.film_id=f.film_id 
LEFT JOIN inventory i ON f.film_id=i.film_id 
LEFT JOIN rental r ON i.inventory_id=r.inventory_id 
LEFT JOIN payment p ON r.rental_id=p.rental_id 
GROUP BY c.category_id
HAVING count(DISTINCT fc.film_id)>60
ORDER BY 2 DESC;


/*6 Какие фильмы чаще всего берут напрокат по субботам? Показать названия
первых 5 по популярности фильмов. Если у фильмов одинаковая
популярность, отдать предпочтение первому по алфавиту.
Подсказка: день недели можно извлечь с помощью EXTRACT*/
SELECT 	f.title,
    	count(rental_id)
FROM film f
LEFT JOIN inventory i ON f.film_id=i.film_id 
LEFT JOIN rental r ON r.inventory_id=i.inventory_id
WHERE extract(dow from rental_date::timestamp)=6
GROUP BY 1
ORDER BY count(rental_id) DESC, f.title ASC
LIMIT 5;

/*7 Распределить фильмы в три категории по длительности:короткие менее 70
средние от 70 до 130 (не вкл.)
длинные 130 и выше
Рассчитать количество прокатов и количество фильмов в каждой такой
категории. Если прокатов у фильма не было, не включать его в расчеты
количества фильмов в категории (подумать над типом джоина 😉).
Подсказка: количество фильмов и количество прокатов не будут
одинаковыми числами, ведь фильмы берут напрокат много раз.
*/
SELECT  CASE 
	      WHEN length < 70 THEN 'короткие'
	      WHEN length < 130 THEN 'средние'
	      WHEN length >=130 THEN 'длинные'
		END AS "Категория", 
		count(DISTINCT f.film_id) AS "Кол-во фильмов",
		count(DISTINCT r.rental_id)AS "Кол-во прокатов"
FROM film f
FULL JOIN inventory i ON f.film_id = i.film_id
INNER JOIN rental r ON i.inventory_id=r.inventory_id
GROUP BY 1
ORDER BY 1;


/* Для последующих запросов создадим таблицу weekly_revenue с выручкой по
неделям и будем работать с ней:*/
CREATE TABLE weekly_revenue AS 
	SELECT EXTRACT(YEAR FROM rental_date) AS r_year,
		   EXTRACT(week FROM rental_date) AS r_week, 
		   sum(amount) AS revenue 
    FROM rental r 
    LEFT JOIN payment p ON p.rental_id=r.rental_id
    GROUP BY 1,2 
    ORDER BY 1,2;
   
SELECT * 
FROM weekly_revenue; 

/*8. Рассчитать накопленную сумму недельной выручки бизнеса.
Вывести всю таблицу weekly_revenue с дополнительным столбцом с
накопленной суммой.
Округлить накопленную выручку до целого числа*/
SELECT *, ROUND( SUM(revenue) OVER(ORDER BY r_year, r_week)) AS cum_avarage
FROM weekly_revenue;

/* 9 Рассчитать скользящую среднюю недельной выручки бизнеса.
Использовать неделю до, текущую неделю, и неделю после для расчета
среднего значения.
Вывести всю таблицу weekly_revenue с дополнительными столбцами с
накопленной суммой и скользящей средней.
Округлить скользящую среднюю до целого числа.
*/
SELECT *, 
	 ROUND( SUM(revenue) OVER(ORDER BY r_year, r_week)) AS cum_avarage,
	 ROUND( AVG (revenue) OVER (ORDER BY  r_year, r_week 
	 							ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)) AS mov_avarage
FROM weekly_revenue;

/*10.Посчитать прирост недельной выручки бизнеса в %.
Прирост в % =
Текущая выручка − Предшествующая выручка
Предшествующая выручка
* 100%
Вывести всю таблицу weekly_revenue с дополнительными столбцами с
накопленной суммой, скользящей средней и приростом.
Округлить прирост в процентах до 2 знаков после запятой.
*/

SELECT *,
	 ROUND( SUM(revenue) OVER(ORDER BY r_year, r_week
	 						  ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS cum_avarage,
	 ROUND( AVG (revenue) OVER (ORDER BY r_year, r_week 
	 							ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING)) AS mov_avarage,
	ROUND((revenue-lag(revenue, 1) OVER my_window)*100.00/lag(revenue, 1) OVER
my_window, 2) AS pct_growth
FROM weekly_revenue
WINDOW my_window AS (
ORDER BY r_year, r_week ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW);
