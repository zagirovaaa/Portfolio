--Необходимо проанализировать данные о фондах и инвестициях и написать запросы к базе. 

--1.Посчитайте, сколько компаний закрылось.

SELECT COUNT(status)
FROM company
WHERE status = 'closed';


--2.Отобразите количество привлечённых средств для новостных компаний США. Используйте данные из таблицы company company. Отсортируйте таблицу по убыванию значений в поле funding_total

SELECT funding_total
FROM company
WHERE category_code = 'news' AND country_code = 'USA'
ORDER BY funding_total DESC;

--3. Найдите общую сумму сделок по покупке одних компаний другими в долларах. Отберите сделки, которые осуществлялись только за наличные с 2011 по 2013 год включительно.

SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash' and EXTRACT(YEAR FROM CAST(acquired_at AS date)) BETWEEN 2011 AND 2013;


--4. Отобразите имя, фамилию и названия аккаунтов людей в поле network_username, у которых названия аккаунтов начинаются на 'Silver'

SELECT first_name,
last_name,
twitter_username
FROM people
WHERE twitter_username LIKE 'Silver%';

--5. Выведите на экран всю информацию о людях, у которых названия аккаунтов в поле network_username содержат подстроку ‘money’, а фамилия начинается на ‘K’

SELECT *
FROM people
WHERE last_name LIKE 'K%' AND network_username LIKE '%money%';

--6.Для каждой страны отобразите общую сумму привлечённых инвестиций, которые получили компании, зарегистрированные в этой стране. Страну, в которой зарегистрирована компания, можно определить по коду страны. Отсортируйте данные по убыванию суммы.

SELECT country_code,
    SUM(funding_total)
FROM company
GROUP BY country_code
ORDER by SUM(funding_total) DESC;

--7. Составьте таблицу, в которую войдёт дата проведения раунда, а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату.
--Оставьте в итоговой таблице только те записи, в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению.

SELECT funded_at,
        MIN(raised_amount),
        MAX(raised_amount)
FROM funding_round
GROUP BY funded_at
HAVING  MIN(raised_amount) !=MAX(raised_amount) AND MIN(raised_amount) !=0;

--8. Создайте поле с категориями:
--Для фондов, которые инвестируют в 100 и более компаний, назначьте категорию ‘high_activity’.
--Для фондов, которые инвестируют в 20 и более компаний до 100, назначьте категорию ‘middle_activity'.
--Если количество инвестируемых компаний фонда не достигает 20, назначьте категорию ‘low_activity'.
Отобразите все поля таблицы fundfound и новое поле с категориями.

SELECT *,
CASE 
 WHEN invested_companies >=100 THEN 'high_activity'
 WHEN invested_companies >= 20 AND invested_companies < 100 THEN 'middle_activity'
 WHEN invested_companies< 20 THEN 'low_activity'
END category
FROM fund;

--9. Для каждой из категорий, назначенных в предыдущем задании, посчитайте округлённое до ближайшего целого числа среднее количество инвестиционных раундов, в которых фонд принимал участие. Выведите на экран категории и среднее число инвестиционных раундов. Отсортируйте таблицу по возрастанию среднего.

SELECT
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity,
      ROUND(AVG(investment_rounds)) AS r --
FROM fund
GRoup BY activity
ORDER BY r;

--10. Проанализируйте, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
--Для каждой страны посчитайте минимальное, максимальное и среднее число компаний, в которые инвестировали фонды этой страны, основанные с 2010 по 2012 год включительно. Исключите страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю. 
--Выгрузите десять самых активных стран-инвесторов: отсортируйте таблицу по среднему количеству компаний от большего к меньшему. Затем добавьте сортировку по коду страны в лексикографическом порядке.

SELECT country_code,
        MIN(invested_companies),
        MAX(invested_companies),
        AVG(invested_companies)
FROM fund
WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) between 2010 and 2012 
GROUP BY  country_code
HAVING MIN(invested_companies)> 0

ORDER BY AVG(invested_companies) DESC, country_code
LIMIT 10;

--11. Отобразите имя и фамилию всех сотрудников стартапов. Добавьте поле с названием учебного заведения, которое окончил сотрудник, если эта информация известна.

SELECT  p.first_name,
        p.last_name,
        e.instituition
FROM people AS p
left outer JOIN education AS e ON p.id=e.person_id;

--12. Для каждой компании найдите количество учебных заведений, которые окончили её сотрудники. Выведите название компании и число уникальных названий учебных заведений. Составьте топ-5 компаний по количеству университетов.

SELECT c.name,
COUNT(DISTINCT e.instituition)
FROM company AS c
JOIN people AS p ON c.id = p.company_id
JOIN education AS e ON p.id = e.person_id
GROUP BY c.name
ORDER BY COUNT(DISTINCT e.instituition) DESC
LIMIT 5;

-- 13.Составьте список с уникальными названиями закрытых компаний, для которых первый раунд финансирования оказался последним.

SELECT DISTINCT c.name
FROM company AS c 
LEFT JOIN funding_round AS fr ON c.id= fr.company_id
WHERE status = 'closed'
AND fr.is_first_round = 1
AND fr.is_last_round = 1;

-- 14.Составьте список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании.

SELECT DISTINCT p.id
FROM people AS p
WHERE p.company_id IN (SELECT  c.id
FROM company AS c 
LEFT JOIN funding_round AS fr ON c.id= fr.company_id
WHERE status = 'closed'
AND fr.is_first_round = 1
AND fr.is_last_round = 1
                      GROUP BY c.id);

--15.Составьте таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущей задачи и учебным заведением, которое окончил сотрудник.

SELECT DISTINCT p.id, 
e.instituition

FROM people AS p
LEFT JOIN education AS e ON p.id= e.person_id
WHERE p.company_id IN (SELECT  c.id
    FROM company AS c 
    LEFT JOIN funding_round AS fr ON c.id= fr.company_id
    WHERE status = 'closed'
    AND fr.is_first_round = 1
    AND fr.is_last_round = 1
    GROUP BY c.id)
    
GROUP BY p.id, e.instituition
HAVING e.instituition IS NOT NULL;

--16. Посчитайте количество учебных заведений для каждого сотрудника из предыдущего задания. При подсчёте учитывайте, что некоторые сотрудники могли окончить одно и то же заведение дважды.

SELECT   p.id,
        COUNT(e.instituition)
FROM people AS p
LEFT JOIN education AS e ON p.id= e.person_id
WHERE p.company_id IN (SELECT  c.id
                            FROM company AS c 
                            LEFT JOIN funding_round AS fr ON c.id= fr.company_id
                            WHERE status = 'closed'
                            AND fr.is_first_round = 1
                            AND fr.is_last_round = 1
                            GROUP BY c.id)
GROUP BY  p.id
HAVING COUNT(DISTINCT e.instituition) >0;

--17. Дополните предыдущий запрос и выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники разных компаний. Нужно вывести только одну запись, группировка здесь не понадобится.

WITH 
tabl AS (SELECT   p.id,
        COUNT(e.instituition) AS total   
FROM people AS p
LEFT JOIN education AS e ON p.id= e.person_id
WHERE p.company_id IN (SELECT  c.id
                            FROM company AS c 
                            LEFT JOIN funding_round AS fr ON c.id= fr.company_id
                            WHERE status = 'closed'
                            AND fr.is_first_round = 1
                            AND fr.is_last_round = 1
                            GROUP BY c.id)
GROUP BY  p.id
HAVING COUNT(DISTINCT e.instituition) >0)

SELECT AVG(total)
FROM tabl;

-- 18.Напишите похожий запрос: выведите среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники Facebook*.
--*(сервис, запрещённый на территории РФ)
WITH 
tabl AS (SELECT   p.id,
        COUNT(e.instituition) AS total   
FROM people AS p
LEFT JOIN education AS e ON p.id= e.person_id
WHERE p.company_id IN (SELECT  c.id
                            FROM company AS c 
                            LEFT JOIN funding_round AS fr ON c.id= fr.company_id
                            WHERE c.name = 'Facebook'
                            GROUP BY c.id)
GROUP BY  p.id
HAVING COUNT(DISTINCT e.instituition) >0)

SELECT AVG(total)
FROM tabl;

--19. Составьте таблицу из полей:
--‘ name_of_fund’ название фонда;
--‘name_of_company’ название компании;
--‘amount’ сумма инвестиций, которую привлекла компания в раунде.
--В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, а раунды финансирования проходили с 2012 по 2013 год включительно.

SELECT f.name AS name_of_fund,
c.name AS name_of_company,
fr.raised_amount AS amount
FROM investment AS i
LEFT JOIN company AS c ON c.id = i.company_id
LEFT JOIN fund AS f ON i.fund_id = f.id
INNER JOIN 
(SELECT*
FROM funding_round
WHERE funded_at BETWEEN '2012-01-01' AND '2013-12-31')
AS fr ON fr.id = i.funding_round_id
WHERE c.milestones > 6;

-- 20.Выгрузите таблицу, в которой будут такие поля:
--название компании-покупателя;
--сумма сделки;
--название компании, которую купили;
--сумма инвестиций, вложенных в купленную компанию;
--доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, округлённая до ближайшего целого числа.
--Не учитывайте те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций в компанию равна нулю, исключите такую компанию из таблицы. 
--Отсортируйте таблицу по сумме сделки от большей к меньшей, а затем по названию купленной компании в лексикографическом порядке. Ограничьте таблицу первыми десятью записями.

WITH
acquiring AS
    (SELECT c.name AS buyer,
a.price_amount AS price,
a.id AS KEY
FROM acquisition AS a
LEFT JOIN company AS c ON a.acquiring_company_id = c.id
WHERE a.price_amount > 0),

acquired AS
    (SELECT c.name AS acquisition,
c.funding_total AS investment,
a.id AS KEY
FROM acquisition AS a
LEFT JOIN company AS c ON a.acquired_company_id = c.id
WHERE c.funding_total > 0)

SELECT acqn.buyer,
acqn.price,
acqd.acquisition,
acqd.investment,
ROUND(acqn.price / acqd.investment) AS uplift
FROM acquiring AS acqn
JOIN acquired AS acqd ON acqn.KEY = acqd.KEY
ORDER BY price DESC, acquisition
LIMIT 10;

--21. Выгрузите таблицу, в которую войдут названия компаний из категории  social, получившие финансирование с 2010 по 2013 год включительно. Проверьте, что сумма инвестиций не равна нулю. Выведите также номер месяца, в котором проходил раунд финансирования.

SELECT c.name,
        EXTRACT(month FROM CAST(fr.funded_at AS date)) AS month
FROM company AS c
LEFT JOIN funding_round AS fr ON c.id= fr.company_id
WHERE c.category_code = 'social' AND fr.raised_amount > 0 
AND fr.funded_at BETWEEN '2010-01-01' AND '2013-12-31'

--22. Отберите данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды. Сгруппируйте данные по номеру месяца и получите таблицу, в которой будут поля:
--номер месяца, в котором проходили раунды;
--количество уникальных названий фондов из США, которые инвестировали в этом месяце;
--количество компаний, купленных за этот месяц;
--общая сумма сделок по покупкам в этом месяце.
WITH fundings AS
(SELECT EXTRACT(MONTH FROM CAST(fr.funded_at AS DATE)) AS funding_month,
COUNT(DISTINCT f.id) AS us_funds
FROM fund AS f
LEFT JOIN investment AS i ON f.id = i.fund_id
LEFT JOIN funding_round AS fr ON i.funding_round_id = fr.id
WHERE f.country_code = 'USA'
AND EXTRACT(YEAR FROM CAST(fr.funded_at AS DATE)) BETWEEN 2010 AND 2013
GROUP BY funding_month),
acquisitions AS
(SELECT EXTRACT(MONTH FROM CAST(acquired_at AS DATE)) AS funding_month,
COUNT(acquired_company_id) AS bought_co,
SUM(price_amount) AS sum_total
FROM acquisition
WHERE EXTRACT(YEAR FROM CAST(acquired_at AS DATE)) BETWEEN 2010 AND 2013
GROUP BY funding_month)
SELECT fnd.funding_month, fnd.us_funds, acq.bought_co, acq.sum_total
FROM fundings AS fnd
LEFT JOIN acquisitions AS acq ON fnd.funding_month = acq.funding_month;

--23.Составьте сводную таблицу и выведите среднюю сумму инвестиций для стран, в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах. Данные за каждый год должны быть в отдельном поле. Отсортируйте таблицу по среднему значению инвестиций за 2011 год от большего к меньшему.

WITH
y11 AS ( SELECT country_code,
                AVG (funding_total) AS t11
       FROM company
       WHERE  EXTRACT(YEAR FROM CAST(founded_at AS DATE)) = 2011 
       GROUP BY country_code),
y12 AS ( SELECT country_code,
                AVG (funding_total) AS t12
       FROM company
       WHERE  EXTRACT(YEAR FROM CAST(founded_at AS DATE)) = 2012 
       GROUP BY country_code),
y13 AS ( SELECT country_code,
                AVG (funding_total) AS t13
       FROM company
       WHERE  EXTRACT(YEAR FROM CAST(founded_at AS DATE)) = 2013
       GROUP BY country_code)
       
SELECT y11.country_code,
       t11,
       t12,
       t13
FROM y11
 JOIN y12 ON y11.country_code= y12.country_code
 JOIN y13 ON y12.country_code= y13.country_code
ORDER BY t11 DESC;

