
CREATE TABLE `users` (
	`uid` VARCHAR(32) NOT NULL DEFAULT PRIMARY KEY,
	`username` varchar(128) CHARACTER SET utf8 COLLATE utf8_unicode_ci NOT NULL,
	`key_id` CHAR(16) NOT NULL,      --- PGP 64-bit key ID
	`fingerprint` CHAR(40) NOT NULL, --- PGP fingerprint required for authentication
	INDEX(`username`),
	INDEX(`key_id`),
	INDEX(`fingerprint`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `threads` (
	`uid` VARCHAR(32),
	`seqid` UNSIGNED INTEGER(11) NOT NULL,
	`status` UNSIGNED INT(11) NOT NULL,
	`ctime` UNSIGNED BIGINT NOT NULL,
	`mtime` UNSIGNED BIGINT NOT NULL,
	`data`  MEDIUMTEXT NOT NULL,
	PRIMARY KEY(`uid`, `seqid`),
	INDEX(`uid`, `ctime`),
	INDEX(`uid`, `mtime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
