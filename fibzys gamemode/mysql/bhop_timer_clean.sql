CREATE DATABASE IF NOT EXISTS `FiBzY-BHOP`;  -- Your database name
USE `FiBzY-BHOP`;  -- Your database name

CREATE TABLE IF NOT EXISTS `timer_admins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `steam` varchar(255) NOT NULL,
  `level` int(11) NOT NULL DEFAULT 0,
  `type` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=30 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `timer_global` (
  `map` varchar(255) NOT NULL,
  `player` varchar(255) DEFAULT NULL,
  `time` int(11) NOT NULL,
  `date` int(11) DEFAULT NULL,
  PRIMARY KEY (`map`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `timer_logging` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `type` int(11) NOT NULL DEFAULT 0,
  `data` text DEFAULT NULL,
  `date` varchar(255) DEFAULT NULL,
  `adminsteam` varchar(255) NOT NULL,
  `adminname` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=307 DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

CREATE TABLE IF NOT EXISTS `timer_map` (
  `map` text NOT NULL,
  `multiplier` int(11) NOT NULL DEFAULT 1,
  `bonusmultiplier` int(11) DEFAULT NULL,
  `plays` int(11) NOT NULL DEFAULT 0,
  `options` int(11) NOT NULL,
  UNIQUE KEY `map` (`map`) USING HASH
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

CREATE TABLE IF NOT EXISTS `timer_replays` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `map` text NOT NULL,
  `player` text DEFAULT NULL,
  `time` decimal(10,4) NOT NULL,
  `style` int(11) NOT NULL,
  `steam` text NOT NULL,
  `date` text NOT NULL,
  `frame` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`frame`)),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

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

CREATE TABLE IF NOT EXISTS `timer_zones` (
  `map` text NOT NULL,
  `type` int(11) NOT NULL,
  `pos1` text DEFAULT NULL,
  `pos2` text DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;