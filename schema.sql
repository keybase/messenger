

CREATE TABLE `msg_threads` (
	thread_id CHAR(32) NOT NULL PRIMARY KEY,       --- at least one for each group of conversants
	num_conversants INT(11) UNSIGNED NOT NULL,     --- the # of conversants in the conversation
	write_key CHAR(64) NOT NULL                    --- conversants need to prove knowledge of this key to write
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `msg_thread_keys` (
	thread_id CHAR(32) NOT NULL,                   --- at least one for each group of conversants
	key_zid INT(11) UNSIGNED NOT NULL,             --- #0, #1, #2, etc. lowest UID gets 0.
	key_data TEXT NOT NULL,                        --- Armor64-ed PGP message
	etime DATETIME NOT NULL,                       --- When to delete the key
	PRIMARY KEY (`thread_id`, `key_zid`),
	CONSTRAINT `msg_thread_keys_ibfk_1` FOREIGN KEY(`thread_id`) REFERENCES `msg_threads` (`thread_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `msg_messages` (
	thread_id CHAR(32) NOT NULL,                   --- at least one for each group of conversants
	msg_zid INT(11) UNSIGNED NOT NULL,             --- The sequence number in the msg_bodies table
	sender_zid INT(11) UNSIGNED NOT NULL,          --- #0, #1, etc... who the sender was
	num_chunks INT(11) UNSIGNED NOT NULL,          --- the number of chunks in the mesasge (usually 1)
	etime DATETIME NOT NULL,                       --- When to delete the message
	PRIMARY KEY (`thread_id`, `msg_zid`),
	CONSTRAINT `msg_messages_ibfk_1` FOREIGN KEY(`thread_id`) REFERENCES `msg_threads` (`thread_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `msg_chunks` (
    thread_id CHAR(32) NOT NULL,                   --- Thread ID
    msg_zid INT(11) UNSIGNED NOT NULL,             --- MSG id integer sequence number in that thread
    chunk_zid INT(11) UNSIGNED NOT NULL,           --- chunk id integer sequence number in that message
    data MEDIUM TEXT NOT NULL,                     --- Encrypted data.
    PRIMARY KEY (`thread_id`, `msg_zid`, `chunk_zid`),
	CONSTRAINT `msg_chunks_ibfk_1` FOREIGN KEY(`thread_id`, `msg_zid`) REFERENCES `msg_messages` (`thread_id`, `msg_zid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE `msg_deletions` (
    thread_id CHAR(32) NOT NULL,                   --- Thread ID
    user_zid INT(11) UNSIGNED NOT NULL,            --- The user who deleted
    msg_zid INT(11) UNSIGNED NOT NULL,             --- Which message s/he deleted at
    PRIMARY KEY (`thread_id`, `user_zid`),
    CONSTRAINT `msg_deletions_ibkf_1` FOREIGN KEY(`thread_id`, `user_zid`) REFERENCES `msg_thread_keys` (`thread_id`, `key_zid`;
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
