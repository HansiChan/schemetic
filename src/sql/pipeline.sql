CREATE CATALOG ${CATALOG} WITH (
  'type' = 'paimon',
  'warehouse' = '${WAREHOUSE}',
  's3.endpoint' = '${S3_ENDPOINT}',
  's3.access-key' = '${S3_ACCESS_KEY}',
  's3.secret-key' = '${S3_SECRET_KEY}',
  's3.path.style.access' = '${S3_PATH_STYLE}'
);

USE CATALOG ${CATALOG};

CREATE DATABASE IF NOT EXISTS ${DATABASE};
USE ${DATABASE};


CREATE TABLE IF NOT EXISTS gmg_smt_patron_rating_hand_by_hand
AS
SELECT
CONCAT(t.uid, '-', t.property, '-', t.game_info_uid, '-', t.box_number, '-', t.bet_option) AS uid, 
t.uid AS hand_by_hand_uid,
t.rating_id,
t.game_info_uid,
t.property,
t.dt,
trim(t.game_id) AS game_id,
t.seated_patron_exists,
t.game_start_datetime,
t.game_finish_datetime,
trim(t.hardware_id) AS table_device_id,
t.operation_id,
t.bet_chip_sum, 
t.pay_off_sum,
t.box_number AS box_number,
t.bet_option AS bet_option,
t.chip_set_name AS chipset_type,
t.bet_amount,
t.payoff_amount,
t.create_datetime
FROM (
-- Unpivot bet options using UNION ALL (Flink SQL compatible, replaces StarRocks json_each)
SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'PlayerWin' AS bet_option,
       bet_chip_player_win_average AS bet_amount,
       COALESCE(pay_off_player_win_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_player_win_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'BankerWin' AS bet_option,
       bet_chip_banker_win_average AS bet_amount,
       COALESCE(pay_off_banker_win_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_banker_win_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'Tie' AS bet_option,
       bet_chip_tie_average AS bet_amount,
       COALESCE(pay_off_tie_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_tie_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'PlayerPair' AS bet_option,
       bet_chip_player_pair_average AS bet_amount,
       COALESCE(pay_off_player_pair_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_player_pair_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'BankerPair' AS bet_option,
       bet_chip_banker_pair_average AS bet_amount,
       COALESCE(pay_off_banker_pair_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_banker_pair_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'Lucky6' AS bet_option,
       bet_chip_lucky6_average AS bet_amount,
       COALESCE(pay_off_lucky6_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_lucky6_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'Lucky6Small' AS bet_option,
       bet_chip_lucky6_small_average AS bet_amount,
       COALESCE(pay_off_lucky6_small_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_lucky6_small_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'Lucky6Big' AS bet_option,
       bet_chip_lucky6_big_average AS bet_amount,
       COALESCE(pay_off_lucky6_big_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_lucky6_big_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'Fortune6' AS bet_option,
       bet_chip_fortune6_average AS bet_amount,
       COALESCE(pay_off_fortune6_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_fortune6_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'Tiger' AS bet_option,
       bet_chip_tiger_average AS bet_amount,
       COALESCE(pay_off_tiger_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_tiger_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'SmallTiger' AS bet_option,
       bet_chip_small_tiger_average AS bet_amount,
       COALESCE(pay_off_small_tiger_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_small_tiger_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'BigTiger' AS bet_option,
       bet_chip_big_tiger_average AS bet_amount,
       COALESCE(pay_off_big_tiger_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_big_tiger_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'TigerTie' AS bet_option,
       bet_chip_tiger_tie_average AS bet_amount,
       COALESCE(pay_off_tiger_tie_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_tiger_tie_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'TigerPair' AS bet_option,
       bet_chip_tiger_pair_average AS bet_amount,
       COALESCE(pay_off_tiger_pair_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_tiger_pair_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'BankerIns1' AS bet_option,
       bet_chip_banker_ins1_average AS bet_amount,
       COALESCE(pay_off_banker_ins1_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_banker_ins1_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'PlayerIns1' AS bet_option,
       bet_chip_player_ins1_average AS bet_amount,
       COALESCE(pay_off_player_ins1_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_player_ins1_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'BankerIns2' AS bet_option,
       bet_chip_banker_ins2_average AS bet_amount,
       COALESCE(pay_off_banker_ins2_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_banker_ins2_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'PlayerIns2' AS bet_option,
       bet_chip_player_ins2_average AS bet_amount,
       COALESCE(pay_off_player_ins2_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_player_ins2_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'Super7' AS bet_option,
       bet_chip_super7_average AS bet_amount,
       COALESCE(pay_off_super7_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_super7_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'SuperLucky' AS bet_option,
       bet_chip_super_lucky_average AS bet_amount,
       COALESCE(pay_off_super_lucky_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_super_lucky_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'Lucky72' AS bet_option,
       bet_chip_lucky72_average AS bet_amount,
       COALESCE(pay_off_lucky72_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_lucky72_average > 0

UNION ALL

SELECT uid, game_id, property, box_number, rating_id, game_info_uid, dt,
       game_start_datetime, game_finish_datetime, hardware_id, operation_id,
       patron_id, create_datetime, seated_patron_exists, bet_chip_sum, pay_off_sum, chip_set_name,
       'Lucky73' AS bet_option,
       bet_chip_lucky73_average AS bet_amount,
       COALESCE(pay_off_lucky73_average, 0) AS payoff_amount
FROM tapdata_patron_rating_hand_by_hand
WHERE bet_chip_sum > 0 AND bet_chip_lucky73_average > 0
) t;

CREATE TABLE IF NOT EXISTS gmg_smt_patron_rating_hand_by_hand_nobet
AS
SELECT
t.uid AS hand_by_hand_uid,
t.rating_id,
t.game_info_uid,
t.property,
t.dt,
trim(t.game_id) AS game_id,
t.seated_patron_exists,
t.game_start_datetime,
t.game_finish_datetime,
trim(t.hardware_id) AS table_device_id,
t.operation_id,
t.bet_chip_sum, 
t.pay_off_sum,
t.box_number AS box_number,
t.chip_set_name AS chipset_type,
t.create_datetime
FROM (
SELECT
	uid,
	rating_id,
	game_info_uid,
	property,
	dt,
	game_id,
	seated_patron_exists,
	game_start_datetime,
	game_finish_datetime,
	hardware_id,
	operation_id,
	bet_chip_sum,
	pay_off_sum,
	box_number,
	patron_id,
	chip_set_name,
	create_datetime
FROM tapdata_patron_rating_hand_by_hand
WHERE
	bet_chip_sum = 0
	AND chip_set_name = 'TOTAL'
) t;