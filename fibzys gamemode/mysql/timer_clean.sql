CREATE TABLE IF NOT EXISTS `timer_admins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steam` varchar(255) NOT NULL,
  `level` int(11) NOT NULL DEFAULT 0,
  `type` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;


INSERT INTO `timer_admins` (`id`, `steam`, `level`, `type`) VALUES
	(1, 'STEAM_0:1:48688711', 32, 2);

CREATE TABLE IF NOT EXISTS `timer_global` (
  `map` varchar(255) NOT NULL,
  `player` varchar(255) DEFAULT NULL,
  `time` int(11) NOT NULL,
  `date` int(11) DEFAULT NULL,
  PRIMARY KEY (`map`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `timer_global` (`map`, `player`, `time`, `date`) VALUES

CREATE TABLE IF NOT EXISTS `timer_logging` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` int(11) NOT NULL DEFAULT 0,
  `data` text DEFAULT NULL,
  `date` varchar(255) DEFAULT NULL,
  `adminsteam` varchar(255) NOT NULL,
  `adminname` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

INSERT INTO `timer_logging` (`id`, `type`, `data`, `date`, `adminsteam`, `adminname`) VALUES

CREATE TABLE IF NOT EXISTS `timer_map` (
  `map` text NOT NULL,
  `multiplier` int(11) NOT NULL DEFAULT 1,
  `bonusmultiplier` int(11) DEFAULT NULL,
  `plays` int(11) NOT NULL DEFAULT 0,
  `options` int(11) DEFAULT NULL,
  UNIQUE KEY `map` (`map`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `timer_map` (`map`, `multiplier`, `bonusmultiplier`, `plays`, `options`) VALUES

INSERT INTO `timer_replays` (`id`, `map`, `player`, `time`, `style`, `steam`, `date`, `frame`) VALUES

CREATE TABLE IF NOT EXISTS `timer_times` (
  `uid` text NOT NULL,
  `player` text DEFAULT NULL,
  `map` text NOT NULL,
  `style` int(11) NOT NULL,
  `time` double NOT NULL,
  `points` float NOT NULL,
  `data` text DEFAULT NULL,
  `date` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `timer_times` (`uid`, `player`, `map`, `style`, `time`, `points`, `data`, `date`) VALUES

CREATE TABLE IF NOT EXISTS `timer_zones` (
  `map` text NOT NULL,
  `type` int(11) NOT NULL,
  `pos1` text DEFAULT NULL,
  `pos2` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

INSERT INTO `timer_zones` (`map`, `type`, `pos1`, `pos2`) VALUES