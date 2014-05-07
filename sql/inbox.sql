
--- 
---  We also need uid <-> username mappings, and also uid <-> key mappings,
---    but we do that via API access to the main keybase.
--- 

-- Incoming notifications get queued here.  Writes to this table aren't authenticated,
-- but might be controlled via postage stamps of some sort.
CREATE TABLE `notifications` (
	`uid` CHAR(32) NOT NULL,
	`thread_id` CHAR(64) NOT NULL,
	`notifcation_zid` UNSIGNED INTEGER(11) NOT NULL,
	`ctime` UNSIGNED BIGINT NOT NULL,
	`status` UNSIGNED INT(11) NOT NULL,
	`data`  MEDIUMTEXT NOT NULL,
	PRIMARY KEY(`uid`, `notification_zid`),
	INDEX(`thread_id`),
	INDEX(`uid`, `ctime`),
	INDEX(`uid`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Weak password that can be exchanged for tokens.
CREATE TABLE `passwords` (
	`uid` CHAR(32) NOT NULL,
	`password` VARCHAR(128) NOT NULL,
	`ctime` UNSIGNED BIGINT NOT NULL,
	`etime` UNSIGNED BIGINT NOT NULL, -- when it was revoked (or 0 if not)
	`status` UNSIGNED INT(11) NOT NULL,
	PRIMARY KEY(`uid`, `password`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `tokens` (
	`uid` CHAR(32) NOT NULL,
	`token` CHAR(64) NOT NULL,
	`ctime` UNSIGNED BIGINT NOT NULL,
	`etime` UNSIGNED BIGINT NOT NULL,        -- when it expires if not pre-expired
	`status` UNSIGNED INT(11) NOT NULL,
	`source_type` UNSIGNED INT(11) NOT NULL, -- can be 1=PW, 2=Token, 3=BitCoin, 
	`source_id` VARCHAR(256) NOT NULL,       -- the address to be blackholed if there's a problem
	`comment` TEXT,                          -- comment on why revoked?
	PRIMARY KEY(`uid`, `token`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `bitcoin_blacklist` (
	`uid` CHAR(32) NOT NULL,
	`token` CHAR(64) NOT NULL,               -- which token was revoked in concert
	`address` VARCHAR(64) NOT NULL,
	`ctime` UNSIGNED BIGINT NOT NULL,
	`status` UNSIGNED INT(11) NOT NULL,
	PRIMARY KEY(`uid`, `address`),
	KEY(`address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- Threads can be written back the server in "compacted form" and encrypted
-- for the user who owns it.  Writes to this table should be authenticated.
-- It's important that the data is encrypted since otherwise someone who
-- comrpomised the server could infer who we communicate with based on the
-- postage.
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
