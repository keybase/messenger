
CREATE TABLE `users` (
	`uid` VARCHAR(32) NOT NULL DEFAULT PRIMARY KEY,
	`username` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
	`key_id` CHAR(16) NOT NULL,      --- PGP 64-bit key ID
	`fingerprint` CHAR(40) NOT NULL, --- PGP fingerprint required for authentication
	INDEX(`username`),
	INDEX(`key_id`),
	INDEX(`fingerprint`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `notifications` (
	`uid` CHAR(32) NOT NULL,
	`notifcation_zid` UNSIGNED INTEGER(11) NOT NULL,
	`ctime` UNSIGNED BIGINT NOT NULL,
	`status` UNSIGNED INT(11) NOT NULL,
	`data`  MEDIUMTEXT NOT NULL,
	PRIMARY KEY(`uid`, `notification_zid`),
	INDEX(`uid`, `ctime`),
	INDEX(`uid`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Threads can be written back the server in "compacted form" and encrypted
-- for the user who owns it.
CREATE TABLE `threads` (
	`uid` CHAR(32) NOT NULL,
	`thread_id` CHAR(32) NOT NULL,
	`ctime` UNSIGNED BIGINT NOT NULL,
	`mtime` UNSIGNED BIGINT NOT NULL,
	`edata` MEDIUMTEXT NOT NULL,
	`status` UNSIGNED INT(11) NOT NULL,
	PRIMARY KEY (`uid`, `thread_id`),
	INDEX (`uid`, `mtime`),
	INDEX (`uid`, `ctime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
