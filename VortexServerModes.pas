unit VortexServerModes;

interface

const
  ERR_NOSUCHNICK       = 401; { "<nickname> :No such nick/channel" }
  ERR_NOSUCHSERVER     = 402; { "<server name> :No such server" }
  ERR_NOSUCHCHANNEL    = 403; { "<channel name> :No such channel" }
  ERR_CANNOTSENDTOCHAN = 404; { "<channel name> :Cannot send to channel" }
  ERR_TOOMANYCHANNELS  = 405; { "<channel name> :You have joined too many channels" }
  ERR_WASNOSUCHNICK    = 406; { "<nickname> :There was no such nickname" }
  ERR_TOOMANYTARGETS   = 407; { "<target> :Duplicate recipients. No message delivered" }
  ERR_NOORIGIN         = 409; { ":No origin specified" }
  ERR_NORECIPIENT      = 411; { ":No recipient given (<command>)" }
  ERR_NOTEXTTOSEND     = 412; { ":No text to send" }
  ERR_NOTOPLEVEL       = 413; { "<mask> :No toplevel domain specified" }
  ERR_WILDTOPLEVEL     = 414; { "<mask> :Wildcard in toplevel domain" }
  ERR_UNKNOWNCOMMAND   = 421; { "<command> :Unknown command" }
  ERR_NOMOTD           = 422; { ":MOTD File is missing" }
  ERR_NOADMININFO      = 423; { "<server> :No administrative info available" }
  ERR_FILEERROR        = 424; { ":File error doing <file op> on <file>" }
  ERR_NONICKNAMEGIVEN  = 431; { ":No nickname given" }
  ERR_ERRONEUSNICKNAME = 432; { "<nick> :Erroneus nickname" }
  ERR_NICKNAMEINUSE    = 433; { "<nick> :Nickname is already in use" }
  ERR_NICKCOLLISION    = 436; { "<nick> :Nickname collision KILL" }
  ERR_USERNOTINCHANNEL = 441; { "<nick> <channel> :They aren't on that channel" }
  ERR_NOTONCHANNEL     = 442; { "<channel> :You're not on that channel" }
  ERR_USERONCHANNEL    = 443; { "<user> <channel> :is already on channel" }
  ERR_NOLOGIN          = 444; { "<user> :User not logged in" }
  ERR_SUMMONDISABLED   = 445; { ":SUMMON has been disabled" }
  ERR_USERSDISABLED    = 446; { ":USERS has been disabled" }
  ERR_NOTREGISTERED    = 451; { ":You have not registered" }
  ERR_NEEDMOREPARAMS   = 461; { "<command> :Not enough parameters" }
  ERR_ALREADYREGISTRED = 462; { ":You may not reregister" }
  ERR_NOPERMFORHOST    = 463; { ":Your host isn't among the privileged" }
  ERR_PASSWDMISMATCH   = 464; { ":Password incorrect" }
  ERR_YOUREBANNEDCREEP = 465; { ":You are banned from this server" }
  ERR_KEYSET           = 467; { "<channel> :Channel key already set" }
  ERR_CHANNELISFULL    = 471; { "<channel> :Cannot join channel (+l)" }
  ERR_UNKNOWNMODE      = 472; { "<char> :is unknown mode char to me" }
  ERR_INVITEONLYCHAN   = 473; { "<channel> :Cannot join channel (+i)" }
  ERR_BANNEDFROMCHAN   = 474; { "<channel> :Cannot join channel (+b)" }
  ERR_BADCHANNELKEY    = 475; { "<channel> :Cannot join channel (+k)" }
  ERR_NOPRIVILEGES     = 481; { ":Permission Denied- You're not an IRC operator" }
  ERR_CHANOPRIVSNEEDED = 482; { "<channel> :You're not channel operator" }
  ERR_CANTKILLSERVER   = 483; { ":You cant kill a server!" }
  ERR_NOOPERHOST       = 491; { ":No O-lines for your host" }
  ERR_UMODEUNKNOWNFLAG = 501; { ":Unknown MODE flag" }
  ERR_USERSDONTMATCH   = 502; { ":Cant change mode for other users" }
  RPL_WELCOME          = 001; { ":Welcome to the Internet Relay Network <nick>!<user>@<host>" }
  RPL_YOURHOST         = 002; { ":Your host is <servername>, running version <version>" }
  RPL_CREATED          = 003; { ":This server was created <date>"  }
  RPL_MYINFO           = 004; { "<server_name> <version> <user_modes> <chan_modes>" }
  RPL_UMODEIS          = 221; { "<user mode string>" - To answer a query about a client's own mode; RPL_UMODEIS is sent back. }
  RPL_LUSERCLIENT      = 251; { ":There are <integer> users and <integer> invisible on <integer> servers" }
  RPL_LUSEROP          = 252; { "<integer> :operator(s) online" }
  RPL_LUSERUNKNOWN     = 253; { "<integer> :unknown connection(s)" }
  RPL_LUSERCHANNELS    = 254; { "<integer> :channels formed" }
  RPL_LUSERME          = 255; { ":I have <integer> clients and <integer> servers" }
  RPL_ADMINME          = 256; { "<server> :Administrative info" }
  RPL_ADMINLOC1        = 257; { ":<admin info>" }
  RPL_ADMINLOC2        = 258; { ":<admin info>" }
  RPL_ADMINEMAIL       = 259; { ":<admin info>" }
  RPL_AWAY             = 301; { "<nick> :<away message>" }
  RPL_ISON             = 303; (* ":[<nick> {<space><nick>}]" *)
  RPL_UNAWAY           = 305; { ":You are no longer marked as being away" }
  RPL_WHOISUSER        = 311; { "<nick> <user> <host> * :<real name>"}
  RPL_WHOISSERVER      = 312; { "<nick> <server> :<server info>"}
  RPL_WHOISOPERATR     = 313; { "<nick> :is an IRC operator"}
  RPL_WHOISCHANOP      = 316;
  RPL_WHOISIDLE        = 317; { "<nick> <integer> :seconds idle"}
  RPL_ENDOFWHOIS       = 318; { "<nick> :End of /WHOIS list" }
  RPL_WHOISCHANNELS    = 319; (* "<nickgt;<space>}" *)
  RPL_WHOWASUSER       = 314; { "<nick> <user> <host> * :<real name>"}
  RPL_ENDOFWHOWAS      = 369; { "<nick> :End of WHOWAS"}
  RPL_LISTSTART        = 321; { "Channel :Users  Name" }
  RPL_LIST             = 322; { "<channel> <# visible> :<topic>" }
  RPL_LISTEND          = 323; { ":End of /LIST" }
  RPL_CHANNELMODEIS    = 324; { "<channel> <mode> <mode params>" }
  RPL_CREATIONTIME     = 329; 
  RPL_NOTOPIC          = 331; { "<channel> :No topic is set" }
  RPL_TOPIC            = 332; { "<channel> :<topic>" }
  RPL_TOPICWHOTIME     = 333;
  RPL_INVITING         = 341; { "<channel> <nick>" }
  RPL_SUMMONING        = 342; { "<user> :Summoning user to IRC }
  RPL_VERSION          = 351; { "<version>.<debuglevel> <server> :<comments>" }
  RPL_WHOREPLY         = 352; { "<channel> <user> <host> <server> <nick> <H|G>[*][@|+] :<hopcount> <real name>" }
  RPL_ENDOFWHO         = 315; { "<name> :End of /WHO list" }
  RPL_NAMREPLY         = 353; { "<channel> :[[@|+]<nick> [[@|+]<nick> [...]]]" }
  RPL_ENDOFNAMES       = 366; { "<channel> :End of /NAMES list"}
  RPL_BANLIST          = 367; { "<channel> <banid>" }
  RPL_ENDOFBANLIST     = 368; { "<channel> :End of channel ban list" }
  RPL_INFO             = 371; { ":<string>" }
  RPL_ENDOFINFO        = 374; { ":End of /INFO list" }
  RPL_MOTDSTART        = 375; { ":- <server> Message of the day - " }
  RPL_MOTD             = 372; { ":- <text>" }
  RPL_ENDOFMOTD        = 376; { ":End of /MOTD command"}
  RPL_YOUREOPER        = 381; { ":You are now an IRC operator" }
  RPL_TIME             = 391; { "<server> :<string showing server's local time>" }
  RPL_USERSSTART       = 392; { ":UserID   Terminal  Host" }
  RPL_USERS            = 393; { ":%-8s %-9s %-8s" }
  RPL_ENDOFUSERS       = 394; { ":End of users" }
  RPL_NOUSERS          = 395; { ":Nobody logged in" }


implementation


end.
