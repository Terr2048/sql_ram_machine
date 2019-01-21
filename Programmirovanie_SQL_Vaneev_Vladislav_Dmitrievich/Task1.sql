-- = IT Planet, SQL 2017/18 =
-- = Task 1 =
--
-- with 
-- volums(v1, v2, v3) as (select 6, 3, 7 from dual),
-- vals(vl1, vl2, vl3) as  (select 4, 0, 6 from dual)
--
------ выполняет основные вычисления, решает задачу
---- curr_state - состояние
-- 0 - подготовка временных значений (t_v11,t_v12,t_v13)
-- 1 - переливание из 1 в 2
-- 2 - из 1 в 3
-- 3 - из 2 в 1
-- 4 - из 2 в 3
-- 5 - из 3 в 1
-- 6 - из 3 в 2
-- 7 - установка указателя памяти (mem_ptr) на следующий шаг
-- (под шагом понимается одно переливание воды между стаканами)
---- prev_state - предыдущее состояние, костыль, нужено для синхронизации 
-- без него mem_ptr может инкрементироваться дважды при удалении шага
---- memory - основная память, содержит граф переходов в виде '0@1@4-0-6 1@2@1-3-6 1@3@3-0-7'
---- mem_ptr - id текущего шага
---- t_v11,t_v12,t_v13 - содержат текущий шаг
---- n - костыль, нужен чтобы oracle не ругался на бесконечную рекурсия (он не видит условия остановки)
, machine(curr_state,prev_state,memory,mem_ptr,t_v11,t_v12,t_v13,n) as (
	select 0, 0, (0||'@'||1||'@'||vl1||'-'||vl2||'-'||vl3), 1, vl1, vl2, vl3, 0 from vals
	union all
	select 
		case
			-- не менять состояние в режиме удаления
			when regexp_count(memory, regexp_substr(memory, '@(\d+)-(\d+)-(\d+)$')) > 1
			then curr_state
			-- цикл состояний
			when curr_state < 7
			then curr_state+1
			else 0
		end,
		curr_state,
		case
			-- удалить последний шаг, если его результат уже встречался
			when regexp_count(memory, regexp_substr(memory, '@(\d+)-(\d+)-(\d+)$')) > 1
			then regexp_replace(memory, '(.*) (\d+)@(\d+)@(\d+)-(\d+)-(\d+)$', '\1')
			-- пропуск шага, если решение уже найдено
			when ((t_v11 = t_v12 and t_v13 = 0)
				or(t_v12 = t_v13 and t_v11 = 0)
				or(t_v13 = t_v11 and t_v12 = 0))
			then memory
			when curr_state = 0 or curr_state = 7
			then memory
			-- 1 -> 2
			when curr_state = 1
			then memory || ' ' || mem_ptr || '@' || (to_number(regexp_replace(memory,'.*?(\d+)@(\d+)@(\d+)-(\d+)-(\d+)$','\2'))+1) || '@' || greatest(t_v11-(v2-t_v12),0) || '-' || least(t_v11+t_v12,v2) || '-' || t_v13
			-- 1 -> 3
			when curr_state = 2
			then memory || ' ' || mem_ptr || '@' || (to_number(regexp_replace(memory,'.*?(\d+)@(\d+)@(\d+)-(\d+)-(\d+)$','\2'))+1) || '@' || greatest(t_v11-(v3-t_v13),0) || '-' || t_v12 || '-' || least(t_v11+t_v13,v3)
			-- 2 -> 1
			when curr_state = 3
			then memory || ' ' || mem_ptr || '@' || (to_number(regexp_replace(memory,'.*?(\d+)@(\d+)@(\d+)-(\d+)-(\d+)$','\2'))+1) || '@' || least(t_v12+t_v11,v1) || '-' || greatest(t_v12-(v1-t_v11),0) || '-' || t_v13
			-- 2 -> 3
			when curr_state = 4
			then memory || ' ' || mem_ptr || '@' || (to_number(regexp_replace(memory,'.*?(\d+)@(\d+)@(\d+)-(\d+)-(\d+)$','\2'))+1) || '@' || t_v11 || '-' || greatest(t_v12-(v3-t_v13),0) || '-' || least(t_v12+t_v13,v3)
			-- 3 -> 1
			when curr_state = 5
			then memory || ' ' || mem_ptr || '@' || (to_number(regexp_replace(memory,'.*?(\d+)@(\d+)@(\d+)-(\d+)-(\d+)$','\2'))+1) || '@' || least(t_v13+t_v11,v1) || '-' || t_v12 || '-' || greatest(t_v13-(v1-t_v11),0)
			-- 3 -> 2
			when curr_state = 6
			then memory || ' ' || mem_ptr || '@' || (to_number(regexp_replace(memory,'.*?(\d+)@(\d+)@(\d+)-(\d+)-(\d+)$','\2'))+1) || '@' || t_v11 || '-' || least(t_v13+t_v12,v2) || '-' || greatest(t_v13-(v2-t_v12),0)
		end,
		case
			when curr_state = 7 and prev_state = 6
			then mem_ptr+1
			else mem_ptr
		end,
		-- подготовка временных значений
		case
			when curr_state = 0
			then to_number(regexp_replace(memory, '.*\d+@' || mem_ptr || '@(\d+)-(\d+)-(\d+).*','\1'))
			else t_v11
		end,
		case
			when curr_state = 0
			then to_number(regexp_replace(memory, '.*\d+@' || mem_ptr || '@(\d+)-(\d+)-(\d+).*','\2'))
			else t_v12
		end,
		case
			when curr_state = 0
			then to_number(regexp_replace(memory, '.*\d+@' || mem_ptr || '@(\d+)-(\d+)-(\d+).*','\3'))
			else t_v13
		end,
		n+1
		from machine, volums
		where n < power(2,31)-1
			-- остановка, если нет возможных шагов
			and mem_ptr <= to_number(regexp_replace(memory,'.*?(\d+)@(\d+)@(\d+)-(\d+)-(\d+)$','\2'))
)
------ парсит результаты, отделяет шаги и сохраняет в отдельный столбец, создает иерархию
---- memory - содержит вершины графов
---- parent_id - id предыдущего шага
---- id - id текущего шага
---- step - столбец с шагами
, parse(memory, parent_id, id, step) as (
	-- выбирает из памяти строки, содержащие ответ, и соединяет их в одну
	select listagg(memory,' ') within group(order by memory), -1, -1, ''
		from 
			(select distinct memory 
				from machine
				where ((regexp_replace(memory,'.*\d+@\d+@(\d+)-(\d+)-(\d+)$','\1') = regexp_replace(memory,'.*\d+@\d+@(\d+)-(\d+)-(\d+)$','\2') and regexp_replace(memory,'.*\d+@\d+@(\d+)-(\d+)-(\d+)$','\3') = 0)
					or (regexp_replace(memory,'.*\d+@\d+@(\d+)-(\d+)-(\d+)$','\2') = regexp_replace(memory,'.*\d+@\d+@(\d+)-(\d+)-(\d+)$','\3') and regexp_replace(memory,'.*\d+@\d+@(\d+)-(\d+)-(\d+)$','\1') = 0)
					or (regexp_replace(memory,'.*\d+@\d+@(\d+)-(\d+)-(\d+)$','\3') = regexp_replace(memory,'.*\d+@\d+@(\d+)-(\d+)-(\d+)$','\1') and regexp_replace(memory,'.*\d+@\d+@(\d+)-(\d+)-(\d+)$','\2') = 0)))
	union all
	select
		-- удаляет последний шаг
		regexp_replace(memory, '(.*) \d+@\d+@\d+-\d+-\d+$', '\1'),
		-- достает parent_id и id из текущего шага
		to_number(regexp_replace(memory,'.*?(\d+)@(\d+)@(\d+-\d+-\d+)$','\1')),
		to_number(regexp_replace(memory,'.*?(\d+)@(\d+)@(\d+-\d+-\d+)$','\2')),
		-- сохраняет текущий шаг в step
		regexp_replace(memory,'.*?(\d+)@(\d+)@(\d+-\d+-\d+)$','\3')
		from parse
		-- пока не закончатся шаги
		where regexp_count(memory, '@(\d+)-(\d+)-(\d+)') > 1
)
------ парсит результаты, преобразует столбец с шагами в их последовательность
---- res - содержит строки с последовательностью верных шагов
, parse2(res) as (
	-- выбирает из иерархии последовательности, содержащие ответ
	select regexp_replace(sys_connect_by_path(step, ', '), '^, (.*)', '\1')
		from 
			(select distinct step, parent_id, id 
			from parse)
		where ((regexp_replace(step,'^(\d+)-(\d+)-(\d+).*','\1') = regexp_replace(step,'^(\d+)-(\d+)-(\d+).*','\2') and regexp_replace(step,'^(\d+)-(\d+)-(\d+).*','\3') = 0)
			or (regexp_replace(step,'^(\d+)-(\d+)-(\d+).*','\2') = regexp_replace(step,'^(\d+)-(\d+)-(\d+).*','\3') and regexp_replace(step,'^(\d+)-(\d+)-(\d+).*','\1') = 0)
			or (regexp_replace(step,'^(\d+)-(\d+)-(\d+).*','\3') = regexp_replace(step,'^(\d+)-(\d+)-(\d+).*','\1') and regexp_replace(step,'^(\d+)-(\d+)-(\d+).*','\2') = 0))
		start with parent_id = 0
		connect by prior id = parent_id
)
-- select 'st'||curr_state||' pst'||prev_state||' ptr'||mem_ptr||' ['||t_v11||'-'||t_v12||'-'||t_v13||'] mem: '||memory from machine
-- select 'p'||parent_id||'	id'||id||'	'||step||' '||memory from parse
select rownum "ID", res "Path" from parse2