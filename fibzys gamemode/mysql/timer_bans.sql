CREATE TABLE IF NOT EXISTS `timer_bans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steamid` varchar(32) DEFAULT NULL,
  `ip` varchar(64) DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `admin` varchar(64) DEFAULT NULL,
  `ban_time` int(11) NOT NULL DEFAULT 0,
  `unban_time` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
