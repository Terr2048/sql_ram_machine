-- = IT Planet, SQL 2017/18 =
-- = Task 3 =
--
--with life as (
-- select  2 x,  1 y from dual union all
-- select  3 x,  1 y from dual union all
-- select  4 x,  1 y from dual union all
-- select  12 x,  1 y from dual union all
-- select  4 x,  2 y from dual union all
-- select  7 x,  2 y from dual union all
-- select  11 x,  2 y from dual union all
-- select  4 x,  3 y from dual union all
-- select  12 x,  3 y from dual union all
-- select  7 x,  4 y from dual union all
-- select  9 x,  4 y from dual union all
-- select  3 x,  5 y from dual union all
-- select  4 x,  5 y from dual union all
-- select  5 x,  5 y from dual union all
-- select  9 x,  6 y from dual union all
-- select  10 x,  6 y from dual union all
-- select  3 x,  7 y from dual union all
-- select  4 x,  7 y from dual union all
-- select  5 x,  7 y from dual union all
-- select  8 x,  7 y from dual),
--iter(it1) as  (select 10 from dual)
--
------ парсит входные данные, делает из них матрицу
---- grid - сетка(матрица), состоит 0 и 1 (клеток)
---- n - позиция вычисляемой клетки
---- life - входные данные
, parse(grid, n, life) as (
	select '', 0, 
		-- преобразуем входные данные к виду ';x-y;x-y;'
		(select ';'||listagg(x||'-'||y,';') within group(order by y)||';' 
			from life)
		from dual
	union all
	select
		-- если текущие координаты есть в начальных условиях - пишем в сетку 1, иначе - 0
		case
			when regexp_like(life, ';'||(mod(n, 12)+1)||'-'||floor((n+12) / 12)||';')
			then grid || '1'
			else grid || '0'
		end,
		n+1,
		life
		from parse
		where n < 12*12
)
------ выполняет основные вычисления, решает задачу
---- curr_state - состояние
-- 0 - вычисление значений клеток
-- 1 - переход к следующей итерации
---- grid - сетка, состоит 0 и 1
---- next_grid - вторая сетка, сюда сохраняются результаты вычисления значений клеток
---- n - позиция вычисляемой клетки
---- i - номер итерации(поколения)
, machine(curr_state, grid, next_grid, n, i) as (
	select 0, grid, '', 1, 1 
		from parse 
		where n = 144
	union all
	select
		case
			when n < 144 or curr_state = 1
			then 0
			else 1
		end,
		case 
			when curr_state = 1
			then next_grid
			else grid
		end,
		case
			when curr_state = 1
			then ''
			-- ищет живые клетки в окрестности текущей
			when regexp_count	(	  regexp_replace(grid, '^\d{'||(n-12-2)||'}1.*','2')||regexp_replace(grid, '^\d{'||(n-12-1)||'}1.*','2')||regexp_replace(grid, '^\d{'||(n-12-0)||'}1.*','2')
									||regexp_replace(grid, '^\d{'||(n-00-2)||'}1.*','2')														||regexp_replace(grid, '^\d{'||(n-00-0)||'}1.*','2')
									||regexp_replace(grid, '^\d{'||(n+12-2)||'}1.*','2')||regexp_replace(grid, '^\d{'||(n+12-1)||'}1.*','2')||regexp_replace(grid, '^\d{'||(n+12-0)||'}1.*','2')
								,'2') = 2
			then next_grid || regexp_replace(grid,'^\d{'||(n-1)||'}(\d).*','\1')
			when regexp_count	(	  regexp_replace(grid, '^\d{'||(n-12-2)||'}1.*','2')||regexp_replace(grid, '^\d{'||(n-12-1)||'}1.*','2')||regexp_replace(grid, '^\d{'||(n-12-0)||'}1.*','2')
									||regexp_replace(grid, '^\d{'||(n-00-2)||'}1.*','2')														||regexp_replace(grid, '^\d{'||(n-00-0)||'}1.*','2')
									||regexp_replace(grid, '^\d{'||(n+12-2)||'}1.*','2')||regexp_replace(grid, '^\d{'||(n+12-1)||'}1.*','2')||regexp_replace(grid, '^\d{'||(n+12-0)||'}1.*','2')
								,'2') = 3
			then next_grid || 1
			else next_grid || 0
		end,
		case
			when curr_state = 1
			then 1
			else n+1
		end,
		case
			when curr_state = 1
			then i+1
			else i
		end
		from machine, iter
		where i < it1 and n < 146
)
------ парсит результаты, форматирует вывод
---- grid - сетка, состоит из 0 и 1
---- res - форматированная сетка, состоит из '   ' и 'X  '
---- n - номер строки
, parse2(grid, res, n) as (
	-- меняет 0 и 1 на пробелы и X соответственно
	select regexp_replace(regexp_replace(grid,'1','X  '),'0','   '), '', 0 
		from machine
		where n = 1
	union all
	select 
		-- удаляет первую строку из сетки
		regexp_replace(grid,'^(.  ){12}(.*)','\2'),
		res 
		-- выравнивает столбец с номерами строк
		||(case
			when n < 9
			then ' '
			else ''
		end)
		-- добавляет нумерацию и переносы строк
		|| regexp_replace(grid,'^((.  ){12}).*',(n+1)||' \1'||chr(10)),
		n+1
		from parse2
		where n < 12
)
-- select regexp_replace(grid, '(\d{12})', '\1'||chr(10)||'\2') from parse where n = 144
-- select regexp_replace(grid, '(\d{12})', '\1'||chr(10)||'\2') from machine where n = 1
select '   1  2  3  4  5  6  7  8  9 10 11 12' || chr(10) || res || 'Iterarion ' || rownum
	from parse2 
	where n = 12