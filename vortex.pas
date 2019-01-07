unit vortex;
{
  Darkling Software Presents.
  TVortex v2.9.5+

  http://www.darkling-software.net

  IRC: joepezT
  Show netiquette on IRC !

  Do not expect any support regarding this component on IRC.
  you are mostly on your own here.

  Email: joepezt(a)bluezone.no (Primary mail)  - (a) = @
         darkling(a)berzerk.net (questions regarding this component)


  Please do not create any virus/malicious trojans using this component,
  if you do, I will have to close the project.

  *****************************************************************
  * YOU MUST HAVE ICS INSTALLED IN ORDER TO USE THESE COMPONENTS. *
  *   ICS can be downloaded FREE from http://www.overbyte.be.     *
  *****************************************************************

  TVortex is a free IRC component by joepezt
  Feel free to use it on whatever you want.
  if you find a bug, or have new features you think might be usefull..

  If you think I deserve anything for developping this component, feel free to
  send me anything you like :D

  note: I have changed alot of the event name to more logical names
  also I am in the work of adding "before" events.

  hope it wont make much problems for you ;)
  many options is now available under

  vortex.IrcOptions.ircnick
  vortex.ctcpoptions.versionreply...
  ...etc etc...

  The other purpose of the "Before" events is that you can abort it.
  example:

  function Tdata.VortexBeforeNotice(Destination, Content: String): Boolean;
  begin
    if (destination = '') or
       (pos('unwanted-word',content) <> 0)  then
    result := false; // This will abort the notice
  end;

  If you plan to use it in your own application,
  please write somewhere that you use vortex, and link to my pages..
  and i also want a copy and test it :)
  you might also put a "Powered by Vortex" on your project ;)

  I would also like to have your projects posted on my page, eighter the
  whole compiled project and or a link to it. or even a small description
  of it.

  If anyone of you find and fixes a bug, please send them back to me
  vortex@berzerk.net. just use "vortex" as subject

  IRC Related information
  RFC1459 : http://vortex.berzerk.net/rfc1459.html

  Last minute news:
  There might be a bug if you get kicked, which somehow stops you from parsing the strings,
  This might also reside in the topic area..
  other bug in the topic is the first time you join you seem to get the nick and timestamp. 

  _____________________________________________________
  these peoples have contributed to the Vortex Project:
  (In no particular order)

  Cubud         : Component writing tips.
  Acryl         : See annotations marked with "Acryl"
  VirusBuster   : Testing DCC capabilities
  LVK, WolfMan, LordCRC.
  + some other people i do not have the names from.


  ******* ******* ******* ******* ******* ******* ******* ******* ******* ******* *******

  January 2004

  I have recently downloaded these very nice sources. During some tests i found some
  significant bugs which i fixed by myself which are:

  -> major bugs in channel user storage, so i rewrote them "from the scratch" (VortexChannels.pas)
     --> a user is stored in an object of a class, which has now variables for
         the nick name and each user mode (recently op and voice, but easy to extend)
     --> the users are stored in a TList
     --> new methods for getting the content are available

         procedure FillListOfUsers(aList : TStrings);
           (empties and) fills a TStrings with the Usernames (with mode prefixes [@, +])

         procedure SetNewUserName(OldName, NewName : string);
           changes a nickname on the list if someone changed his nick in a channel,
           so the usermodes will be kept

         all other routines remain the same functionality, propably implementation is new

  -> full implementation of user and channel information storage in
     these routines
     --> Joined
     --> Parted
     --> Quited
     --> Kicked
     --> NickChange

  -> user and channel modes are now implementet
     --> new Routines to set User and Chanmodes

         procedure ChannelMode (NickName, ChannelName, NewMode, Params : string);
           sets the new modes for the channel, easy to extend (see source)

         procedure UserMode  (Nickname, ChannelName, Victim, NewMode : string);
           sets then new modes for a user in a channel (see source, too)


  -> new event which is thown on an error during joining a channel (like invite only etc)

  -> some help routines

       function StripNextParam(var aParams: string): string;
         cuts and returns the first param (without the blank) of a set of blank separated params
         (needed for the mode change routines)

  There might still be bugs or some routines that don't work fine, but it is currently
  quite useful.

  Greets,
  Christoph Boos

  Last minute:

  I discovered a problem on reading the socket after the application freezes for some time.
  It is possible that more than 1 message arrives the parser at the same time.
  I had no ideas yet. 
  ******* ******* ******* ******* ******* ******* ******* ******* ******* ******* *******

}

{$D+}

interface
 uses
  Classes, SysUtils, VortexChannels, VortexCommon, VortexServerModes,
 {$IFDEF MSWINDOWS} Controls, Windows, wsocket;
 {$ELSE} { Linux Kylix }
   QControls, QDialogs, IcsSocket;
 {$ENDIF}

  type
    { commands which will be triggered AFTER you send them OR from the server }
    TOnNotifyResult   = procedure (Sender : Tobject; NotifyUsers : string) of object;
    TOnChannelmsg     = procedure (Sender : Tobject; Channelname,Content,Nickname, Ident, Mask : string) of object;
    TOnModeChange     = procedure (Sender : Tobject; Nickname, Destination, Mode, Parameter: string)    of object;
    TOnNoSuchNick     = procedure (Sender : Tobject; Value : string) of object;
    TOnNotice         = procedure (Sender : Tobject; NickName, Content : string) of object;
    TOnWhoList        = procedure (Sender : Tobject; ChannelName, Nickname,Username,Hostname, Name, Servername,status,other : string; EndOfWho : boolean) of object;
    TOnChannelList    = procedure (Sender : Tobject; ChannelName, Topic : string; Users : integer; EndOfList : boolean) of object;
    TOnNamesList      = procedure (Sender : Tobject; Commanicks, ChannelName : string; endofnames : boolean)                of object;
    TOnWhoisDisplay   = procedure (Sender : Tobject; Info : string; EndOfWhois : boolean)                               of object;
    TOnMotdDisplay    = procedure (Sender : Tobject; Line : string; EndOfMotd : boolean) of object;
    TOnPrivmsg        = procedure (Sender : Tobject; Nickname, Ident, Mask, Content : string) of object;
    TOnNickInUse      = procedure (Sender : Tobject; Nickname : string)      of object;
    TOnUserTopic      = procedure (Sender : Tobject; ChannelName,Nickname,Topic : string) of object;
    TOnUserCtcp       = procedure (Sender : Tobject; Nickname, Command, Destination : string) of object; // Acryl : Modified ( see DataReceive-Handler for explanation )
    TOnUserKick       = procedure (Sender : Tobject; KickedUser, Kicker, ChannelName, Reason : string) of object;
    TOnUserQuit       = procedure (Sender : Tobject; Nickname, User, Host, Reason : string)   of object;
    TOnUserNickChange = procedure (Sender : Tobject; Oldnick, Newnick : string) of object; { not me }
    TOnUserJoin       = procedure (Sender : Tobject; Nickname, Hostname,ChannelName : string) of object;
    TOnUserPart       = procedure (Sender : Tobject; Nickname,Hostname,Channelname,Reason : string) of object;
    TOnCannotJoin     = procedure (Sender : Tobject; Servername, Channel, Nick, Reason: string) of object;
    { Events before triggered }
    TBeforeDisconnect = function : boolean of object;
    TBeforeConnect    = function (Sender : Tobject; Ircserver,Ircport : string) : Boolean of object;
    TBeforeQuit       = function (Sender : Tobject; Reason : string) : Boolean of object;
    TBeforeQuote      = function (Sender : Tobject; raw : string) : Boolean of object;
    TBeforeJoin       = function (Sender : Tobject; Channelname : string) : Boolean of object;
    TBeforePart       = function (Sender : Tobject; Channelname : string) : Boolean of object;
    TBeforeMode       = function (Sender : Tobject; Nickname, Commands, parameters : string) : Boolean of object;
    TBeforeTopic      = function (Sender : Tobject; Channelname, Topic   : string) : Boolean of object;
    TBeforePrivmsg    = function (Sender : Tobject; Destination, Content : string) : Boolean of object;
    TBeforeNotice     = function (Sender : Tobject; Destination, Content : string) : Boolean of object;
    TBeforeNickChange = function (Sender : Tobject; Oldnick, Newnick     : string) : Boolean of object;
    { Events After Triggered }
    TAfterServerPing  = procedure (Sender : Tobject) of object;
    TAfterDisconnect  = procedure (Sender : Tobject) of object;
    TAfterConnect     = procedure (Sender : Tobject) of object;
    TAfterNickChanged = procedure (Sender : Tobject; Oldnick, Newnick : string) of object; { me }
    TAfterKicked      = procedure (Sender : Tobject; Nickname, ChannelName, Reason  : string) of object;
    TAfterJoined      = procedure (Sender : Tobject; Channelname : string) of object;
    TAfterParted      = procedure (Sender : Tobject; Channelname : string) of object;
    TAfterPrivmsg     = procedure (Sender : Tobject; Nickname, Ident, Mask, Content : string) of object;
    TIrcAction        = procedure (Sender : Tobject; NickName, Content, Destination : string)      of Object; // Acryl : added
    TOnUserInvite     = procedure (Sender : Tobject; NickName, ChannelName : string) of ObjecT;       // Acryl : added
    { DCC relevant }
    TDccChatIncoming = procedure (Sender : Tobject; Nickname, Port,Address : string) of object;
    TDccChatOutgoing = procedure (Sender : Tobject; Nickname, Port,Address : string) of object;
    TDccSendResume   = procedure (Sender : Tobject; Nickname, Filename, Port, Position : string) of object;
    TDccGetResume    = procedure (Sender : Tobject; Nickname, Filename, Port, Position : string) of object;
    TDccSend         = procedure (Sender : Tobject; Nickname, Port,Address, Filename, Filesize : string) of object;
    TDccGet          = procedure (Sender : Tobject; Nickname, Port,Address, Filename, Filesize : string) of object;
    { commands which will be triggered from the server }
    TStartEvent      = procedure (Sender : Tobject) of object;
    TAuthConnected   = procedure (Sender : Tobject) of object;
    TOnError         = procedure (Sender : Tobject; Error : word) of object;
    TBGException     = procedure (Sender : Tobject; E : Exception; Var CanClose : boolean) of Object;
    TServerError     = procedure (Sender : Tobject; ErrorString : string) of object;
    TOnServerMessage = procedure (Sender : Tobject; Command : string) of object;


  { IdentD/Auth server }
  type
    TAuthOptions = class(TPersistent)
  private
    Fmainthread : integer;
    FSystem  : string;
    FIdent   : string;
    FAnswer  : boolean;
    FEnabled : boolean;
    FOwner      : Integer;
    FAuthServer : TVortexSocket;
  protected
    procedure OnIdentDserverSessionAvailable(Sender: TObject; Error: Word);
  public
    procedure Assign(Source : TPersistent); override;
    procedure StartAuth;
    procedure StopAuth;
  published
    property System  : string  read FSystem  write FSystem;
    property Ident   : string  read FIdent   write FIdent;
    property UseAuth : Boolean read FEnabled write FEnabled; { to start the service }
    property Enabled : Boolean read FAnswer  write FAnswer;  { to answer on requests. }
  end;

  { some component expanded options }
  type
    TIrcOptions = class(TPersistent)
  private
    FServerHost  : string;
    FServerPort  : string;
    FUserNick    : string;
    FUserName    : string;
    FUserIdent   : string;
    FQuitMessage : string;
    FIgnoreColor : Boolean;
    FNotifyList  : TStringlist;
    procedure SetNotifyList(const Value: TStringlist);
  public
    procedure Assign(Source : TPersistent); override;
  published
    property NotifyList    : TStringlist read FNotifyList write SetNotifyList;
    property GetServerHost : string read FServerHost;
    property GetServerPort : string read FServerPort;
    property GetUserNick   : string read FUserNick;
    property GetUserName   : string read FUserName;
    property GetUserIdent  : string read FUserIdent;
    property SetServerHost : string write FServerHost;
    property SetServerPort : string write FServerPort;
    property SetUserNick   : string write FUserNick;
    property SetUserName   : string write FUserName;
    property SetUserIdent  : string write FUserIdent;
    property ServerHost    : string read FServerHost write FServerHost;
    property ServerPort    : string read FServerPort write FServerPort;
    property UserName      : string read FUserName   write FUserName;
    property UserIdent     : string read FUserIdent  write FUserIdent;
    property MyNick        : string read FUserNick   write FUserNick;
    property IgnoreColors  : boolean read FIgnoreColor write FIgnoreColor;
    property DefaultQuitMessage : string read FQuitMessage write FQuitMessage;
  end;

  type
    TCtcpOptions = class(TPersistent)
  private
    FVersionReply : string;
    FTimeReply    : string;
    FFingerReply  : string;
    FPingReply    : string;
    FClientInfo   : string;
    {FUnknownReply : string;}
    FReplyToPing  : boolean;
    FReplyToCtcp  : boolean; { if we decide not to reply at all }
  public
    procedure Assign(Source : TPersistent); override;
  published
    property GetVersionInfo : string read  FVersionReply;
    property GetTimeReply   : string read  FTimeReply;
    property GetFingerReply : string read  FFingerReply;
    property GetPingReply   : string read  FPingReply;
    property VersionReply   : string read  FVersionReply write FVersionReply;
    property TimeReply      : string read  FTimeReply    write FTimeReply;
    property FingerReply    : string read  FFingerReply  write FFingerReply;
    property PingReply      : string read  FPingReply    write FPingReply;
    property ReplyOnPing    : Boolean read FReplyToPing write FReplyToPing;
    property AnswerCtcps    : Boolean read FReplyToCtcp write FReplyToCtcp;
  end;

  type
    TSocksOptions = class(TPersistent)
  private
    FSocksLevel    : string;
    FSocksPort     : string;
    FSocksServer   : string;
    FSocksPassword : string;
    FSocksUserCode : string;
    {$IFDEF MSWINDOWS}
      FSocksAuthentication : TSocksAuthentication;
    {$ENDIF}
  public
  published
    property SocksPort      : string read FSocksPort     write FSocksPort;
    property SocksServer    : string read FSocksServer   write FSocksServer;
    property SocksPassword  : string read FSocksPassword write FSocksPassword;
    property SocksLevel     : string read FSocksLevel    write FSocksLevel;
    property SocksUserCode  : string  read FSocksUserCode write FSocksUserCOde;
    {$IFDEF MSWINDOWS}
      property SocksAuthentication : TSocksAuthentication read FSocksAuthentication write FSocksAuthentication;
    {$ENDIF}
  end;

  { Main component }
  Type
    TVortex = class(TComponent)
  private
    { expanded properties }
    FIrcOptions   : TIrcOptions;
    FCtcpOptions  : TCtcpOptions;
    FSocksOptions : TSocksOptions;
    FAuthOptions  : TAuthOptions;
    { some variuables }
    FCurrentServer  : string;  { Which server are we connected to ? }
    FConnected   : boolean; { Am I connected (?) }

    FClientSocket   : TVortexSocket;

    { Dcc Related events }
    FDccGet            : TDccGet;
    FDccGetResume      : TDccGetResume;
    FDccSend           : TDccGet;
    FDccSendResume     : TDccGetResume;
    FDccChatIncoming   : TDccChatIncoming;
    FDccChatOutgoing   : TDccChatIncoming;
    { All below is IRC Related and triggered before }
    FBeforeQuote       : TBeforeQuote;
    FBeforeConnect     : TBeforeConnect;
    FBeforeDisconnect  : TBeforeDisconnect;
    FBeforeQuit        : TBeforeQuit;
    FBeforeJoin        : TBeforeJoin;
    FBeforeTopic       : TBeforeTopic;
    FBeforePart        : TBeforePart;
    FBeforePrivmsg     : TBeforePrivmsg;
    FBeforeNickChange  : TBeforeNickChange;
    FBeforeNotice      : TBeforeNotice;
    FBeforeMode        : TBeforeMode;
    { All below is IRC Related and triggered after something }
    FAfterNickChanged  : TAfterNickChanged;
    FAfterDisconnect   : TAfterDisconnect;
    FAfterKicked       : TAfterKicked;
    FAfterParted       : TAfterParted;
    FAfterConnect      : TAfterConnect;
    FAfterjoined       : TAfterJoined;
    FAfterServerPing   : TAfterServerPing;
    FAfterPrivMsg      : TAfterPrivMsg;
    FircAction         : TIrcAction;
    FOnUserInvite      : TOnUserInvite;
    FOnError           : TOnError;
    FOnUserTopic       : TOnUserTopic;
    FOnModeChange      : TOnModeChange;
    FOnChannelmsg      : TOnChannelmsg;
    FOnChannelList     : TOnChannelList;
    FOnNoSuchNick      : TOnNoSuchNick;
    FOnNotifyResult    : TOnNotifyResult;
    FOnNotice          : TOnNotice;
    FOnWhoisDisplay    : TOnWhoisDisplay;
    FOnWhoList         : TOnWhoList;
    FOnNickInUse       : TOnNickInUse;
    FOnNamesList       : TOnNamesList;
    FOnMotdDisplay     : TOnMotdDisplay;      { Message of the day }
    FOnPrivmsg         : TOnPrivmsg;
    FOnUserKick        : TOnUserKick;
    FOnUserQuit        : TOnUserQuit;
    FOnUserPart        : TOnUserPart;
    FOnUserJoin        : TOnUserjoin;
    FOnUserCTCP        : TOnUserCTCP;
    FOnUserNickChange  : TOnUserNickChange;
    FOnServerMessage   : TOnServerMessage;
    FServerError       : TServerError;
    FStart             : TStartEvent;
    FBgException       : TBGException;
    FOnCannotJoin      : TOnCannotJoin;
    {Identd related }
    FAuthConnected     : TAuthConnected;
    { these are executed when you join part got kicked... }
    procedure SetIRCMode   (destination, command, parameters: string);
    procedure Parted    (Nickname, HostName, UserName, ChannelName, Reason : string);
    procedure Joined    (Nickname, ChannelName,HostName : string);
    procedure Kicked    (Victim, BOFH, ChannelName, Reason : string);
    procedure Quited    (Nickname, user, host, reason : string);
    procedure UserMode  (Nickname, ChannelName, Victim, NewMode : string);
    procedure ChannelMode (NickName, ChannelName, NewMode, Params : string);
    procedure NamesChan    (ChannelName, CommaNicks : string; EndOfNames : boolean);
    procedure NickChange   (OldNick, Newnick : string);
    procedure Messages     (Line, NickName, host, user, destination, Content : string);
    procedure CTCPMessage  (Line, NickName, host, user, destination, Content : string);
    procedure ChannelTopic (ChannelName, UserName, Topic  : string);
    procedure ChannelTopicSetBy (ChannelName, Nickname  : string);
    { Mask is always the param (format: Nickname!Ident@some.host.com) }
    function GetNickFromMask     (S : string) : string;  // e.g. Vortex2345
    function GetHostmaskFromMask (S : string) : string;  // e.g. vortex@dialup23123.Dubplates.org
    function GetIdentFromMask    (S : string) : string;  // e.g. My Vortex name
    function GetHostFromMask     (S : string) : string;
    procedure SetIrcOptions(const Value: TIrcOptions);
    procedure SetCtcpOptions(const Value: TCtcpOptions);
    procedure SetSocksOptions(const Value: TSocksOptions);
    procedure SetAuthOptions(const Value: TAuthOptions);
    procedure SetupSocket(ConnectToServer : boolean);
    { Misc commands }
    procedure SetCurrentServer (Value    : string);
    procedure SetVersionInfo   (Info     : string);
    procedure SetMyUserName    (Value    : string);
    procedure SetIRCPort       (Value    : string);
    procedure SetIRCName       (Value    : string);
    procedure SetMyNick        (Nickname : string);
    function UserInChannel(nickname, channelname: string): boolean;  // This one does NOT change your NickName on IRC

    function StripNextParam(var aParams : string) : string;

  protected
    procedure OnConnectDataAvailable(Sender: TObject; Error: Word);
    procedure OnSocketDataAvailable(Sender: TObject; Error: Word);
    procedure OnSocketClosed(Sender: TObject; Error: Word);
    procedure OnSocketConnected(Sender: TObject; Error: Word);
    procedure OnVortexIRCError (Sender: TObject);
    procedure OnVortexBgException(Sender: TObject; E: Exception;  var CanClose: boolean);
  public
    FChannels   : TStringList; { A List containing our channels.. }
    constructor Create(AOwner : TComponent); override;
    destructor  Destroy; override;
    procedure   Loaded; override;

    { first thing sent to IRC when you connect. should not be used by user..}
    procedure genericparser (socketmessage : string);
    // function User (NickName, user, ConnectMethod, realname : string) : string;
    function Between(S,Start,stop:string)  : string;
    function LongIP(IP : string)           : string; { Acryl : Modified }
    function ShortIP(const S: string)      : string; { Acryl : Modified }
    { user commands goes here...  }
    procedure InitDccSendResume(NickName, port, Position : string);
    procedure InitDccChat      (NickName, port, address  : string);
    procedure InitDccSend      (NickName, port, address, filename, filesize : string);
    procedure InitDccGet(NickName, port,address, filename, filesize : string);
    procedure InitDccGetResume(NickName, port, Position : string);
    { Raw Commands (quote and raw is the same.. ) }
    procedure Quote     (_Quote : string);
    procedure Raw       (_raw : string);
    procedure NoticeChannelOps (DestinationChannel,Content : string);
    procedure Notice    (destination, content : string);
    procedure Say       (destination, content : string);
    procedure SayAction (destination, content : string);
    procedure SendCTCP  (NickName, command : string);
    procedure CtcpReply (NickName, command : string);
    procedure Join      (channelName : string;key    : string = '');
    procedure Part      (channelName : string;reason : string = '');
    procedure Quit      (reason         : string);
    procedure Kick      (Victim, channelName : string; Reason : string = '');
    procedure lookup   (dns : string);
    procedure Ban     (NickName, mask, ChannelName : string);
    procedure Op      (NickName, ChannelName       : string);
    procedure Deop    (NickName, ChannelName       : string);
    procedure Voice   (NickName, ChannelName       : string);
    procedure DeVoice (NickName, ChannelName       : string);
    procedure Topic   (ChannelName : string; topic : string = '');
    { Request change NickName on IRC }
    procedure Nick    (newnick : string);
    { Info commands...}
    procedure ListChannels (max,min : integer);
    procedure who          (mask : string);
    procedure whowas       (NickName : string);
    procedure whois        (NickName : string;server : string = '');
    { Connect is used by the Server procedure.. }
    procedure connect;
    procedure Server      (server : string; ircport : string = '6667');
    procedure Disconnect  (force          : boolean; reason : string = '');
    function LocalIP           (num      : byte = 0)   : string;
    { ChannelName Related   }
    procedure ClearUsersInChannel  (value    : string);
//    function FindChannelID         (AChannel : string) : integer;
    function CountUsersFromChannel (Value    : string) : integer;
    function GetChannelTopic       (value    : string) : string;
    function GetTopicSetBy         (value    : string) : string;
    function GetUsersFromChannel   (Value    : string) : string;
  published
    property GetCurrentServer : string Read FCurrentServer;
    property IsConnected    : boolean Read FConnected;
    { sub items }
    property IrcOptions     : TIrcOptions   read FIrcOptions   write SetIrcOptions;
    property CtcpOptions    : TCtcpOptions  read FCtcpOptions  write SetCtcpOptions;
    property SocksOptions   : TSocksOptions read FSocksOptions write SetSocksOptions;
    property AuthOptions    : TAuthOptions  read FAuthOptions  write SetAuthOptions;
    { User-defined event handlers  }
    property BeforeQuote         : TBeforeQuote      read FBeforeQuote         write FBeforeQuote;
    property BeforeConnect       : TBeforeConnect    read FBeforeConnect       write FBeforeConnect;
    property BeforeDisconnect    : TBeforeDisconnect read FBeforeDisconnect    write FBeforeDisconnect;
    property BeforeQuit          : TBeforeQuit       read FBeforeQuit          write FBeforeQuit;
    property BeforeJoin          : TBeforeJoin       read FBeforeJoin          write FBeforeJoin;
    property BeforeTopic         : TBeforeTopic      read FBeforeTopic         write FBeforeTopic;
    property BeforePart          : TBeforePart       read FBeforePart          write FBeforePart;
    property BeforePrivateMessage: TBeforePrivmsg    read FBeforePrivmsg       write FBeforePrivmsg;
    property BeforeNickChange    : TBeforeNickChange read FBeforeNickChange    write FBeforeNickChange;
    property BeforeNotice        : TBeforeNotice     read FBeforeNotice        write FBeforeNotice;
    property BeforeMode          : TBeforeMode       read FBeforeMode          write FBeforeMode;
    property AfterPrivateMessage : TAfterprivMsg     read FAfterPrivmsg        write FAfterPrivmsg;
    property AfterJoined         : TAfterjoined      read FAfterJoined         write FAfterJoined;
    property AfterParted         : TAfterParted      read FAfterParted         write FAfterParted;
    property AfterKicked         : TAfterKicked      read FAfterKicked         write FAfterKicked;
    property AfterNickChanged    : TAfterNickChanged read FAfterNickChanged    write FAfterNickChanged;
    property AfterStarted        : TStartEvent       read FStart               write FStart;
    property AfterServerPing     : TAfterServerPing  read FAfterServerPing     write FAfterServerPing;
    property OnUserInvite        : TOnUserInvite     read FOnUserInvite        write FOnUserInvite;    {Acryl : added}
    property OnUserNickChange    : TOnUserNickChange read FOnUserNickChange    write FOnUserNickChange;
    property OnUserCtcp          : TOnUserCTCP       read FOnUserCTCP          write FOnUserCTCP;
    property OnUserJoin          : TOnUserJoin       read FOnUserJoin          write FOnUserJoin;
    property OnUserPart          : TOnUserPart       read FOnUserPart          write FOnUserPart;
    property OnUserQuit          : TOnUserQuit       read FOnUserQuit          write FOnUserQuit;
    property OnUserKick          : TOnUserKick       read FOnUserKick          write FOnUserKick;
    property OnUserTopic         : TOnUserTopic      read FOnUserTopic         write FOnUserTopic;
    property OnServerError       : TServerError      read FServerError         write FServerError;
    property OnMessageChannel    : TOnChannelmsg     read FOnChannelmsg        write FOnChannelmsg;
    property OnMessageAction     : TIrcAction        read FIrcAction           write FIrcAction;      {Acryl : added}
    property OnMessagePrivate    : TOnPrivmsg        read FOnPrivmsg           write FOnPrivmsg;
    property OnMessageNotice     : TOnNotice         read FOnNotice            write FOnNotice;
    property OnIRCCannotJoin     : TOnCannotJoin     read FOnCannotJoin        write FOnCannotJoin;
    property OnIRCNickInUse      : TOnNickInUse      read FOnNickInUse         write FOnNickInUse;
    property OnIRCNoSuchNickChannel : TOnNoSuchNick  read FOnNoSuchNick        write FOnNoSuchNick;
    property OnIRCNotify         : TOnNotifyResult   read FOnNotifyResult      write FOnNotifyResult;
    property OnIRCNames          : TOnNamesList      read FOnNamesList         write FOnNamesList;
    property OnIRCWhois          : TOnWhoisDisplay   read FOnWhoisDisplay      write FOnWhoisDisplay;
    property OnIRCList           : TOnChannelList    read FOnChannelList       write FOnChannelList;
    property OnIRCMode           : TOnModeChange     read FOnModeChange        write FOnModeChange;
    property OnIRCMotd           : TOnMotdDisplay    read FOnMotdDisplay       write FOnMotdDisplay;
    property OnIRCWho            : TOnWhoList        read FOnWhoList           write FOnWhoList;
    property OnServerQuote       : TOnServerMessage  read FOnServerMessage     write FOnServerMessage;
    { Dcc related events, you can use them with my other components }
    property OnDccFileGet        : TDccGet          read FDccGet               write FDccGet;
    property OnDccFileGetResume  : TDccGetResume    read FDccGetResume         write FDccGetResume;
//    property OnDccFileSendResume : TDccGetResume    read FDccGetResume         write FDccGetResume;
    property OnDccChat           : TDccChatIncoming read FDccChatIncoming      write FDccChatIncoming;
    { Socket related stuff }
    property SocketAuth          : TAuthConnected   read FAuthConnected        Write FAuthConnected;
    property SocketDisconnect     : TAfterDisconnect Read FAfterDisconnect     write FAfterDisconnect;
    property SocketConnect       : TAfterConnect    Read FAfterConnect         write FAfterConnect;
    Property SocketError         : TOnError         Read FOnError              write FOnError;
    Property SocketBgException   : TBgException     Read FBGException          write FBGException;
end;

procedure Register;

implementation

////////////////////////////////////////////////////////////////////////////////
////////////////////////// Misc constants //////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Const
  MWG_VERSION_MAJOR     = '2';
  MWG_VERSION_MINOR     = '9';
  {$IFDEF MSWINDOWS}
  MWG_VERSION_TAG       = 'Vortex IRC component for Delphi';
  {$ELSE}
  MWG_VERSION_TAG       = 'Vortex IRC component for Kylix';
  {$ENDIF}
  CrLf                  = #13#10;
  ChannelPrefix = '#!&+'; { <- # = Normal channels  ! = Secure channels (?)
                               & = Local channels   + = Mode less channels }

  Commands: Array [0..37] of integer =
  (324,329,                     // get MODE
   301,311,312,313,317,318,319, // Whois return codes
   401,433,303,                 // Nickname in use, IsON
   315,352,                     // who...
   332,333,                     // topic set
   353,366,                     // names / end of.
   321,322,323,324,             // ChannelName Listing
   250,251,252,253,254,255,     // Motd stuff
   265,266,373,372,375,376,     // Motd stuff
   471, 473,474, 475            // joining errors
   );

{ Match the different IRC Numeric commands }
function match (cmd: string) : integer;
var
Token : integer;
begin
  Token := 0;
  while Token <= High(Commands) do
  begin
    if Cmd = inttostr(Commands[Token]) then
    begin
      Result := commands[Token];
      exit;
    end;
    Inc(Token);
  end;
  result := -1;
end;

procedure Register;
begin
  RegisterComponents('joepezT', [TVortex]);
end;


{ ------------------------------------------------------------------
                        Constructor / Destructor
  ------------------------------------------------------------------
}

{ TVortex }

procedure TVortex.SetupSocket(ConnectToServer : boolean);
begin
  if assigned(FClientSocket) then
     FClientSocket.Free;

  FClientSocket := TVortexSocket.Create(nil);

  with FIrcOptions,
        FSocksOptions,
        FClientSocket do
  Begin
    if not Assigned(FChannels) then
      FChannels := TStringList.Create;

    if assigned(FBeforeConnect) then
    if FBeforeConnect(self, GetServerHost, GetServerPort) = true then
    Exit;

    if GetServerPort       = '' then SetServerPort := '6667';
    if trim(GetServerHost) = '' then exit; { exit if there is no address specified }
    OnDataAvailable    := OnConnectDataAvailable;
    OnSessionClosed    := OnSocketClosed;
    OnError            := OnvortexIRCError;
    OnBgException      := OnVortexBgException;
    OnSessionConnected := OnSocketConnected;
    { socks stuff }
    SocksPort     := FsocksPort;
    SocksServer   := FSocksServer;
    Sockspassword := FSocksPassword;

    { unstable }
    {    SocksLevel    := FSocksLevel;
    SocksUserCode := FSocksUserCode;}
    {SocksAuthentication := TSocksAuthentication;}

    LineEdit := False;
    LineEcho := False;
    LineMode := True;
    LineEnd  := #10;
    Proto := 'tcp';
    Port  := FIrcOptions.GetServerPort;
    Addr  := FIrcOptions.GetServerHost;


    if ConnectToServer then
    Connect;
  end;
end;

Constructor TVortex.Create(AOwner: TComponent);
Begin
  Inherited Create(Aowner);
  FIrcOptions   := TIrcOptions.Create;
  FCtcpOptions  := TCtcpOptions.Create;
  FSocksOptions := TSocksOptions.Create;
  FAuthOptions  := TAuthOptions.Create;
  with FIrcOptions,
       FAuthOptions,
       FCtcpOptions,
       FSocksOptions do
  begin
    FOwner      := Integer(Pointer(Self));
    FNotifyList := TStringlist.create;

    if GetServerHost = '' then SetServerHost := 'stockholm.se.eu.undernet.org';
    if GetServerPort = '' then SetServerPort := '6667';
    if GetUserName   = '' then SetUserName   := 'IRC Component';
    if GetUserIdent  = '' then SetUserIdent  := 'Vortex';
    if GetUserNick   = '' then SetUserNick   := 'Vortex' + inttostr(random(999));
    if FSystem       = '' then FSystem       := 'UNIX';
    if FIdent        = '' then FSystem       := 'Vortex';
    if FFingerReply  = '' then FFingerReply  := 'FooBar';
    if FClientInfo   = '' then FClientInfo   := format('CLIENTINFO Vortex engine, version: %s %s %s',[MWG_VERSION_MAJOR,MWG_VERSION_MINOR,MWG_VERSION_TAG]);
    if FSocksPassword = '' then FSocksPassword := '5';
  end;

  SetVersionInfo(format('Vortex - v%s.%s.',[MWG_VERSION_MAJOR,MWG_VERSION_MINOR]));


  If not (csDesigning in ComponentState) Then
  Begin
  end;
End;

Destructor TVortex.Destroy;
Begin
  If not (csDesigning in ComponentState) Then
  Begin
    DeleteObjects(FIRCoptions.FNotifyList);
    DeleteObjects(FClientSocket);
    DeleteObjects(Fchannels);
    DeleteObjects(FAuthOptions.FAuthServer);
  End;

  inherited Destroy();
End;


procedure TVortex.Loaded();
Begin
  Inherited Loaded();
  If not (csDesigning in ComponentState) Then
  begin
    { if we decide to use identd server }
    With FAuthOptions do
    begin
      if FEnabled = true then
      StartAuth;
    end;

  If Assigned(FStart) Then FStart(self);
  end;
End;

////////////////////////////////////////////////////////////////////////////////
// String manipulation functions
// Great string manipulation which i got from Wolfman :)
////////////////////////////////////////////////////////////////////////////////

function TVortex.Between(S,Start,stop:string):string;
Var      P1,P2:integer;
Begin
  P1:=Pos(start,s);
  P2:=pos(stop,s);
  Result:=copy(s,p1+1,p2-p1-1);
End;

function TVortex.shortIP(const S: string): string;
Var
  IP         : int64;
  A, B, C, D : Byte;
Begin
  {
   ShortIP
   Example: 3232235777 -> 192.168.1.1
  }
  IP := StrToInt64(S);
  A  := (IP and $FF000000) shr 24;
  B  := (IP and $00FF0000) shr 16;
  C  := (IP and $0000FF00) shr 8;
  D  := (IP and $000000FF);
  Result := Format('%d.%d.%d.%d', [A, B, C, D]);
End;

{ Long IP converted by joepezt }
function TVortex.LongIP(IP : string) : string;
var
IPaddr   : array[1..4] of word;
temp     : string;
res      : Longword;
i        : integer;

begin
  temp := ip;
  temp := temp + '.';
  for i := 1 to 4 do
  begin
    try
      ipaddr[i] := strtoint(copy(temp,1,pos('.',temp) - 1));
      delete(temp,1,pos('.',temp));
      if ipaddr[i] > 255 then raise exception.Create('');
    except
     result := 'Invalid IP address.';
     exit;
    end;
  end;

  res := (ipaddr[1] * $FFFFFF) + ipaddr[1] + (ipaddr[2] * $FFFF)   + ipaddr[2] + (ipaddr[3] * $FF)     + ipaddr[3] + (ipaddr[4]);
  result := format('%u',[res]);
end;

////////////////////////////////////////////////////////////////////////////////
// Command parsers by Acryl
////////////////////////////////////////////////////////////////////////////////
function  TVortex.GetNickFromMask(S : string) : string;
Var
 C         : integer;
 TmpString : string;

Begin
  S := Trim(S);
  If (Length(S) = 0) Then Exit;
  TmpString := '';
  For C:=1 To Length(S) Do
  Begin
    If (S[C] = '!') Then break;
    TmpString := TmpString + S[C];
  End;
  Result := TmpString;
end;

function  TVortex.GetIdentFromMask(S : string) : string;
Var
  C       : integer;
  Copying : boolean;
  TmpString : string;
Begin
  S := Trim(S);
  If (Length(S) = 0) Then Exit;
  TmpString := '';
  Copying    := False;
  For C:=1 To Length(S) Do
  Begin
    If (S[C] = '@') Then break;
    If (S[C] = '!') Then Copying := True
    else If (Copying) Then TmpString := TmpString + S[C];
  End;
  Result := TmpString;
end;

function  TVortex.GetHostFromMask(S : string) : string;
Var
 C       : integer;
 Copying : boolean;
 TmpString : string;
Begin
  S := Trim(S);
  If (Length(S) = 0) Then exit;
  TmpString := '';
  Copying    := False;
  For C:=1 To Length(S) Do
  Begin
    If (S[C] = '@') Then Copying := True
    else If (Copying) Then TmpString := TmpString + S[C];
  End;
  Result := TmpString;
end;

function  TVortex.GetHostmaskFromMask(S : string) : string;
Var
  C       : integer;
  Copying : boolean;
  TmpString : string;

Begin
  S := Trim(S);
  If (Length(S) = 0) Then Exit;
  TmpString := '';
  Copying    := False;
  For C:=1 To Length(S) Do
  Begin
    If (S[C] = '!') Then Copying := True
    else If (Copying) Then TmpString := TmpString + S[C];
  End;
  Result := TmpString;
end;


{
-------------------------------------------------------------------
                             User commands
-------------------------------------------------------------------
}
procedure TVortex.Quote(_quote : string);
Begin
  if assigned(FBeforeQuote) then
  if FBeforeQuote(self, _Quote) = true then Exit;;

  if Assigned(FClientSocket) then
  FClientSocket.sendstr(_quote + crlf);
End;

procedure TVortex.Raw(_raw : string);
Begin
  if assigned(FBeforeQuote) then
  if FBeforeQuote(self, _raw) = true then Exit;
  Quote(_raw + crlf);
End;

procedure TVortex.Say(destination, content : string);
Begin
  if Assigned(FBeforePrivmsg) then
  if FBeforePrivmsg(self, destination, content) = True then Exit;;
  Quote(format('PRIVMSG %s :%s',[destination,content]));
End;

procedure TVortex.Notice(destination, content : string);
begin
  if assigned(FBeforeNotice) then
  if FBeforeNotice(self, destination,content) = True then Exit;;

  Quote(format('NOTICE %s :%s',[destination,content]));
end;

procedure TVortex.NoticeChannelOps(DestinationChannel,
  Content: string);
begin
  if assigned(FBeforeNotice) then
  if FBeforeNotice(self, destinationChannel,content) = True then Exit;;
  { sends this notice to ChannelName ops  }
  Quote(format('WALLCHOPS %s :%s',[destinationChannel,content]));
end;

procedure TVortex.whois(NickName, server : string);
begin
  if server <> '' then
  Quote(format('WHOIS %s %s',[NickName,server]))
  else Quote(format('WHOIS %s',[NickName]))
end;

procedure TVortex.listChannels (max,min : integer);
begin
 { LIST <3,>1,C<10,T>0  ; 2 users, younger than 10 min., topic set.
   probably a better way to do this  }
  if min <0 then
  if max >0 then
  begin
    Quote(format('List <%d,>%d',[max,min]));
    exit
  end;
  if min >0 then
  begin
    Quote(format('List >%d',[min]));
    exit
  end;
  if max >0 then
  begin
    Quote(format('List <%d',[max]));
    exit;
  end;
end;

procedure TVortex.who(mask : string);
begin
  Quote(format('WHO %s',[Mask]))
end;

procedure TVortex.whowas(NickName : string);
begin
  quote(format('WHOWAS %s',[NickName]))
end;

procedure TVortex.Op(NickName, ChannelName : string);
begin
  if assigned(FBeforeMode) then
  if FBeforeMode(self, NickName,'op',ChannelName) = True then Exit; ;
  Quote(format('MODE %s +oooo %s',[ChannelName,NickName]));
end;

procedure TVortex.Deop(NickName, ChannelName : string);
begin
  if assigned(FBeforeMode) then
  if FBeforeMode(self, NickName,'deop',ChannelName) = True then Exit;;
  Quote(format('MODE %s -oooo %s',[ChannelName,NickName]));
end;

procedure TVortex.Voice(NickName, ChannelName : string);
begin
  if assigned(FBeforeMode) then
  if FBeforeMode(self, NickName,'voice',ChannelName) = True then Exit;;

   Quote(format('MODE %s +vvvv %s',[ChannelName,NickName]));
end;

procedure TVortex.DeVoice(NickName, ChannelName : string);
begin
  if assigned(FBeforeMode) then
  if FBeforeMode(self, NickName,'devoice',ChannelName) = True then Exit;;
  Quote(format('MODE %s -vvvv %s',[ChannelName,NickName]));
end;

procedure TVortex.SetIRCMode(destination, command, parameters : string);
begin
  if assigned(FBeforeMode) then
  if FBeforeMode(self, Destination,Command,Parameters) = True then Exit;
  Quote(format('MODE %s %s %s',[destination,command,parameters]));
end;

procedure TVortex.Ban(NickName, mask, ChannelName : string);
begin
{  if assigned(FBeforeMode) then
     FBeforeMode(Destination,Command,Parameters);}
  Quote(format('MODE %s +b %s',[ChannelName,mask]));
end;

procedure TVortex.Topic(ChannelName, Topic : string);
begin
  if assigned(FBeforeTopic) then
  if FBeforeTopic(self, ChannelName,topic) = True then Exit;;

  Quote(format('TOPIC %s :%s',[ChannelName,Topic]));
end;

procedure TVortex.Kick(Victim, ChannelName, Reason : string);
begin
   Quote(format('KICK %s %s :%s',[ChannelName,victim,reason]));
end;

procedure TVortex.join(ChannelName : string;key : string = '');
begin
  if assigned(FBeforeJoin) then
  if FBeforeJoin(self, ChannelName)  = True then Exit;;

 if key <> '' then
    Quote(format('Join %s :%s',[ChannelName,key]))
    else
    Quote(format('Join %s',[ChannelName]))
end;

procedure TVortex.connect;
begin
  SetupSocket(true);
end;


procedure TVortex.InitDccchat(NickName,port,address : string);
var
CustomLongIP : string;

begin
  if port = '' then port := '59';
  if address = '' then customlongip := longip(localip(0))
  else CustomLongIP := longip(address);

  Say(NickName,format('%sDcc CHAT chat %s %s%s',[#1,CustomLongIP, port,#1]));
end;

procedure TVortex.InitDccsend(NickName, port,Address, filename, filesize : string);
var
CustomLongIP : string;

begin
  if port = '' then port := '59';
  if address = '' then customlongip := longip(localip(0))
  else CustomLongIP := longip(address);

  Say(NickName,format('%sDcc SEND "%s" %s %s %s%s',[#1,filename, CustomLongIP, port, filesize,#1]));
end;

procedure TVortex.InitDccsendResume(NickName, port, Position : string);
begin
  Quote(format('PRIVMSG %s :' + #1 + 'Dcc RESUME file.ext %s %s',[NickName, port, position]));
end;

procedure TVortex.Part(ChannelName,reason : string);
begin
  if assigned(FBeforePart) then
  if FBeforePart(self, ChannelName) = True then Exit;;

  if reason <> '' then
  Quote(format('part %s :%s',[ChannelName,reason]))
  else Quote(format('part %s',[ChannelName]))
end;

procedure TVortex.Quit(reason : string);
Begin
 { change it to whatever you want  }
  if assigned(FBeforeQuit) then
  if FBeforeQuit(self, reason) = True then Exit;

  If (trim(Reason) = '') Then
  Reason := FIrcOptions.DefaultQuitMessage;
  Quote(format('QUIT :%s',[reason]));
End;

procedure TVortex.SendCTCP(NickName, command : string);
Begin
  Quote(format('PRIVMSG %s :%s%s',[NickName,#1,command]));
End;

procedure TVortex.CtcpReply(NickName, command : string);
Begin
  Quote(format('NOTICE %s :%s%s%s',[NickName,#1,command,#1]));
End;

procedure TVortex.Disconnect(force : boolean; reason : string);
var
i : integer;
Begin
  if assigned(FBeforeDisconnect) then
  if FBeforeDisconnect = True then Exit;

  If (not force) Then Quit(reason)
  Else if Assigned(FClientSocket) then FClientSocket.close;

  FConnected := False;

  if assigned(FChannels) then
  begin
    With FChannels do
    begin
      for i := 0 to count -1 do
      TChannels(FChannels.Objects[i]).free;
    end;
    FChannels.clear;
  end;

End;

procedure TVortex.Nick(newnick : string);
Begin
  Quote(format('Nick :%s',[newnick]))
End;

procedure TVortex.Server(server,ircport : string);
Begin
  { connect to IRC, or reconnect... }
  if assigned(FClientSocket) then
  begin
    If (FConnected) Then Quit('Vortex - Changing server.');
        Fconnected := false;
  end;
  with FIrcOptions do
  begin
    SetServerHost := server;
    SetServerPort := ircport;
    SetupSocket(true);
  end;

end;

procedure TVortex.OnConnectDataAvailable(Sender: TObject; Error: Word);
var
received : string;
temp     : string;
Command  : integer;
i        : integer;
{ On Connect Events
 This one is used during connection! }

begin
  if not assigned(FClientSocket) then
  exit;

  received := trim(TVortexSocket(sender).ReceiveStr);

  if IrcOptions.FIgnoreColor then { if we want to ignore color codes }
  temp := StripCc(received)
  else temp := received;

  { Remove garbage. }
  delete(temp,1,pos(' ',temp));
  delete(temp,pos(' ',temp),length(temp));

  { Trigger server (dataavailable / any data) }
  If Assigned(FOnServerMessage) then
     FOnServerMessage(self,Received);

  { Reply to Server Pings, to avoid disconnection }
  If copy(received,1,4) = 'PING' Then
  Begin
    Quote('PONG ' + copy(received,6,length(received)));
    if assigned(FAfterServerPing) then FAfterServerPing(self);
    Exit;
  end;

  If copy(received,1,5) = 'ERROR' Then
    Begin
      if assigned(FServerError) then
         FServerError(self, Received);
      exit;
    end;

  If copy(received,1,11) = 'NOTICE AUTH' Then
  Begin
    If assigned(FOnNotice) then
       FOnNotice(self, 'server',copy(received,14,length(received)));
    Exit;
  end;


  If copy(temp,1,6) = 'NOTICE' Then
  Begin
    temp := Copy(received,Pos(#32#58,received)+2,Length(received));
    If assigned(FOnNotice) then
       FOnNotice(self, 'server',temp);
    Exit;
  end;


  { Ensure temp is a number }
  if isnumeric(temp) then command := strtoint(temp);
  temp := received;

  case command of
  001..003:
  begin
    if command = 001 then
    begin
    { Grab my NickName & Local server name from the start }
      FCurrentServer := trim(copy(temp,2,pos(' ',temp)-1));
      for i := 0 to 1 do
      delete(received,1,pos(' ',received));
      SetMyNick(trim(copy(received,1,pos(' ',received))));
    end;

    for i := 0 to 1 do
    delete(temp,1,pos(':',temp));
    if assigned(FOnMotdDisplay) then
       FOnMotdDisplay(self, temp,false);
       exit;
  end;



  004,005:
  begin
 { We can extract lots of good information on these lines
   Oslo.NO.EU.undernet.org u2.10.10.pl18.(release) dioswkg biklmnopstv
   SILENCE=15 WHOX WALLCHOPS USERIP CPRIVMSG CNOTICE MODES=6 MAXCHANNELS=10 MAXBANS=30 NICKLEN=9 TOPICLEN=160 KICKLEN=160 CHANTYPES=+#& :are supported by this server
   PREFIX=(ov)@+ CHANMODES=b,k,l,imnpst CHARSET=rfc1459 NETWORK=Undernet :are supported by this server
 }

   { Get Server name }
    SetCurrentServer(copy(temp,2,pos(' ',temp)));

    for i := 1 to 3 do
    delete(temp,1,pos(' ',temp));

    temp := stringreplace(temp,' :',' ', [rfReplaceAll]);
    if assigned(FOnMotdDisplay) then
       FOnMotdDisplay(self, trim(temp),false);
    exit;
  end;

  251..255:
  begin
    if (command = 251) or (command = 255) then
    begin
      for i := 1 to 2 do
      delete(temp,1,pos(':',temp));
      temp := stringreplace(temp,' :',' ', [rfReplaceAll]);
      if assigned(FOnMotdDisplay) then FOnMotdDisplay(self, temp,false);
      exit;
    end;
    for i := 1 to 3 do
    delete(temp,1,pos(' ',temp));
    temp := stringreplace(temp,' :',' ', [rfReplaceAll]);
    if assigned(FOnMotdDisplay) then FOnMotdDisplay(self, temp,false);
    exit;
  end;

  376,422:
  begin
  { Assign all incoming data to alternate events }
    for i := 0 to 1 do
    delete(temp,1,pos(':',temp));
    if assigned(FOnMotdDisplay) then
    FOnMotdDisplay(self, temp,true);

      with TVortexSocket(Sender) do
      begin
      {$IFDEF MSWINDOWS}
        Flush;
      {$ENDIF}
        OnDataAvailable := OnSocketDataAvailable;
      end;
    exit;
  end;

  { Might be buggy =/ }
  433: If Assigned(FOnNickInUse) Then
       with FIrcOptions do
          FOnNickInUse(self, GetUserNick);
  end;

end;

procedure TVortex.genericparser (socketmessage : string);
var
  Token,I,j    : integer;
  Received,    Backup,
  ChannelName, Temp,
  CmdFrom,         // Who sent us this command ?
  CmdName,         // What command is it ?
  CmdTo,           // To whom does this go - irgnored most of the time
  CmdMiddle,       // Possible Middle string;
  CmdAllParams : string; // Everything past :
  Params       : Array[0..10] Of String;  // just extra parameters, used for temporary strings

  {
  Format of Standart Messages:
  :From MessageType To :Parameters
      From can either be:
              Server.host.address
      Or:
              Nickname!ident@host.mask.com
 Some special messages:
  NOTICE Constant/To :Message
      Constant is e.g. AUTH
  PING :From
      From is server.address.com
 CTCPS are sent as privmsgs delimited by #1 at beginning & end

 Sometimes Messages got the following format:
 :From MessageType To SomethingElseHere :Parameters
 If this is the case "S1omethingElseHere" will be stroed in cmdMiddle
 }

begin
  received := trim(socketmessage);
  Backup   := Received;

  { Quick exit - unlikely but possible still }
  If (Length(Received) = 0) Then exit;

  { Command parsing. }

  { If From is specified ... }
  If (Received[1] = ':') Then
  Begin
    I := Pos(' ', Received);
    If (I > 2) Then CmdFrom := Copy(Received,2,I-2);
    Delete(Received,1,I);
  End;

  { Now get the command name }
  Begin
    I := Pos(' ', Received);
    If (I > 1) Then CmdName := Copy(Received,1,I-1);
    Delete(Received,1,I);
  ENd;

  { Now check if there is an additional constant or "to" }
  If (Received[1] <> ':') Then
  Begin
    I := Pos(' ', Received);
    If (I > 1) Then CmdTo := Copy(Received,1,I-1);
    Delete(Received,1,I);
  End;

  { Now check if there is an additional middle-string }
  If (Received[1] <> ':') Then
  Begin
    I := Pos(' ', Received);
    If (I > 1) Then CmdMiddle := Copy(Received,1,I-1);
    Delete(Received,1,I);
  End;

  { Now the get the rest with out the ":" }
  If (Length(Received) > 1) Then
    If (Received[1] = ':') Then CmdAllParams := Copy(Received,2,Length(Received)-1)
    Else CmdAllParams := Received;

  //////////////////////////////////////////////////////////////////
  ///////////////////////// END OF PARSING /////////////////////////
  //////////////////////////////////////////////////////////////////

  { Restore the original received string.              }
  Received := Backup;

  { Trigger server (dataavailable / any data)          }
  If Assigned(FOnServerMessage) then
  FOnServerMessage(self, Received);

  { Reply to Server Pings, to avoid disconnection      }
  If (uppercase(cmdName) = 'PING') Then
  Begin
    Quote('PONG ' + cmdAllParams);
    if assigned(FAfterServerPing) then FAfterServerPing(self);
    Exit;
  end;

  {
   User Joining, (this includes me as well)
   (nickname host ChannelName)
  }
  If (uppercase(cmdName) = 'JOIN') Then
  Begin
    Joined(GetNickFromMask(cmdFrom),cmdAllParams,GetHostmaskFromMask(cmdFrom));
    exit;
  end;

  { User quitting }
  If (uppercase(cmdName) = 'QUIT') Then
  Begin
  {
   (nickname reason)
   :NickName!user@host QUIT :reason
  }
    Quited(GetNickFromMask(cmdFrom), GetHostMaskFromMask(CmdFrom), GetIdentFromMask(CmdFrom), cmdAllParams);
    exit;
  end;

  { User parting (this includes me as well)
   (nickname host ChannelName reason) }
  If (uppercase(cmdName) = 'PART') Then
  Begin
  for I := 0 to 1 do  { get channelname  }
    params[I] := received;
    delete(params[0],1,lastdelimiter('#',received)-1);
    delete(params[0],pos(':',params[0])-1,length(params[1])-1);

  { get part reason  }
    delete(params[1],1,pos(':',params[1]));
    Parted(GetNickFromMask(cmdFrom),GetHostMaskFromMask(CmdFrom),GetIdentFromMask(CmdFrom),params[0],params[1]);
    exit;
  End;

  { This one is very incomplete..  }
  If (uppercase(cmdName) = 'MODE') Then
  Begin

    // decide which sort of mode (what if both?)
    if (CmdMiddle = '') or // CmdMiddle empty?
       not ( // not a usermode ?
         (pos('o', cmdMiddle) <> 0) or (pos('v', cmdMiddle) <> 0) // these are user modes
       )  then
      begin

        // so it must be a channelmode
        ChannelMode(GetNickFromMask(cmdFrom), CmdTo, '', cmdAllParams);

      end
    else
      begin

        // so it must be a single user mode
        UserMode(GetNickFromMask(cmdFrom), CmdTo, CmdAllParams, CmdMiddle);

      end;

    If Assigned(FOnModeChange) and (cmdFrom <> '') then
        FOnModeChange(self, GetNickFromMask(cmdFrom),CmdTo, cmdAllParams, CmdMiddle);

    Exit;
  end;

  {
  There are 2 types of NOTICEs:
   1. NOTICE Constant :SomeTextHere                (coming from server)
   2. :NickName!ident@host.com NOTICE To :SomeTextHere (coming from user 'NickName')
  }
  If (uppercase(cmdName) = 'NOTICE') Then
  Begin
    If Assigned(FOnNotice) Then
    Begin
      If (cmdFrom <> '') Then
      if assigned(FOnNotice) then
        FOnNotice(self, GetNickFromMask(cmdFrom),cmdAllParams)
        Else if assigned(FOnNotice) then
        FOnNotice(self, '',cmdAllParams);
    end;
    Exit;
  End;

  If (uppercase(cmdName) = 'INVITE') Then
  Begin
  { :NickName!Ident@host.com INVITE MyNick :ChannelName  }
    If Assigned(FOnUserInvite) Then
       FOnUserInvite(self, GetNickFromMask(cmdFrom),cmdAllParams);
    Exit;
  End;

  { User was kicked }
  If (uppercase(cmdName) = 'KICK') Then
  begin
    { there might be a bug here if I am kicked, beware }

    Kicked(CmdMiddle,GetNickFromMask(CmdFrom), CmdTo,CmdAllParams);
    exit;
  end;

  If (uppercase(cmdName) = 'TOPIC') Then
  Begin
  {
    SOmeone changed the topic
    :NickName!ident@host.com TOPIC ChannelName :NewTopic
  }
    ChannelTopic(cmdTo,GetNickFromMask(cmdFrom),CmdAllParams);
    Exit;
  End;

  If (uppercase(cmdName) = 'NICK') Then
  Begin
  { :NickName!Ident@host.com NickName <newnick> }
    NickChange(GetNickFromMask(cmdFrom),CmdAllParams);
    exit;
  End;

  If (UpperCase(cmdName) = 'PRIVMSG') Then
  Begin
    { this might be removed later...   }
    If (Length(cmdAllParams) = 0) Then Exit;
    Messages(received,GetNickFromMask(cmdFrom),GetHostFromMask(CmdFrom),GetIdentFromMask(CmdFrom),CmdTo,CmdAllParams);
    exit;
  end;

  If (UpperCase(cmdName) = 'ERROR:') Then
    Begin
    { these error codes appears often right after you connect   }
      if assigned(FServerError) then FServerError(self, Received);
      exit;
    end;



{ Number to command translator as shown in RFC1459
 putting the most unused stuff at the bottom.
 Sorted after how often they likely would appear }
  Token := match(CmdName);
  case Token of
    RPL_CHANNELMODEIS,
    RPL_CREATIONTIME :
    begin { Message of the day stuff }
      if assigned(FOnModeChange) then
      FOnModeChange(self, GetNickFromMask(cmdFrom),CmdTo, cmdAllParams, CmdMiddle);
      exit;
    end;

    RPL_NAMREPLY:
    Begin
     {  Names
        :irc.server.com 353 To = ChannelName :SpaceSperatedNickList
        (@ and + prefixes are included)
        ChannelName, CommaNicks, end of names = false  }
      temp := received;
      ChannelName := received;
      delete(ChannelName,1,pos('#',ChannelName)-1);
      delete(ChannelName,pos(' ',ChannelName),length(ChannelName));
      delete(temp,1,pos(' :',temp)+1);
      NamesChan(ChannelName,temp,false);
      Exit;
    End;

    RPL_ENDOFNAMES:  { end of /names }
    begin
      ChannelName := received;
      delete(ChannelName,1,pos('#',ChannelName)-1);
      delete(ChannelName,pos(' ',ChannelName),length(ChannelName));
      NamesChan(ChannelName,cmdAllParams,true);
      Exit;
    end;

    RPL_WHOISUSER,    RPL_WHOISSERVER,
    RPL_WHOISOPERATR, RPL_WHOWASUSER,
    RPL_WHOISCHANOP,  RPL_WHOISIDLE,
    RPL_ENDOFWHOIS,   RPL_WHOISCHANNELS,
    RPL_AWAY:
    begin
    { Whois thingie... }
      If Assigned(FOnWhoisDisplay) Then
      begin
        if Token <> 318 then FOnWhoisDisplay(self, CmdAllParams, false)
        else FOnWhoisDisplay(self, CmdAllParams, true);  // End of /whois
        exit
      end;
    end;

    RPL_ISON:
    begin { Ison }
      If assigned(FOnNotifyResult) then
      FOnNotifyResult(self, CmdAllParams);
      exit;
    end;

    ERR_NEEDMOREPARAMS: { :irc.homelien.no 461 joepezt ISON :Not enough parameters }
    begin
       exit;
    end;

    RPL_WHOREPLY,RPL_ENDOFWHO: { who stuff }
    Begin
      If Assigned(FOnWhoList) Then
      if Token <> 315 then
      begin
        temp := received;
        for I := 0 to 3 do
        delete(temp,1,pos(' ',temp));

        { user host server NickName away/here ??? :navn channelname }
        params[7] := Cmdmiddle;
        params[6] := trim(copy(temp,pos(':',temp)+2,length(temp)));
        for I  := 0 to 5 do
        begin
          params[I] := trim(copy(temp,1,pos(' ',temp)));
          delete(temp,1,pos(' ',temp));
        end;
        if assigned(FOnWhoList) then
           FOnWhoList(self, params[7], params[3], params[0], params[1], params[6], params[2], params[4], params[5],  false)
      end
        else FOnWhoList(self, 'End of /Who','','','','','','','', true);  // End of /whois
      exit;
    End;

    RPL_TOPIC,RPL_TOPICWHOTIME: { Topic when joining a ChannelName }
    Begin { :Diemen.NL.EU.Undernet.org 332 joepezT #somechannel :some topic }
      if (Token = RPL_TOPICWHOTIME) then
      begin { :Diemen.NL.EU.Undernet.org 333 joepezT #skien blygblome 1033906982 }
            if ChannelName = '' then
            begin
              ChannelName := CmdFrom;
              ChannelName := Cmdto;
            end;
        ChannelTopicSetBy(ChannelName,CmdAllParams);
        Exit;
      end;

      if ChannelName = '' then
        ChannelName := CmdMiddle;

      ChannelTopic(ChannelName,'',CmdAllParams);
      Exit;
    end;

    ERR_NOSUCHNICK:
    begin
      {
         No such nich / ChannelName
         fix ;)
      }
      If Assigned(FOnNoSuchNick) Then
      FOnNoSuchNick(self, CmdFrom);
      exit;
    end;

    ERR_NICKNAMEINUSE:
    begin
      { Nickname is allready in use
        :irc.server.com 433 * OldNickName :Description
      }
      If Assigned(FOnNickInUse) Then
         FOnNickInUse(self, cmdMiddle);
      exit;
    end;

    RPL_LISTSTART,
    RPL_LIST,
    RPL_LISTEND:
    begin
    {
      ChannelName listing. Example: LIST <3,>1,C<10,T>0  ;
      2 users, younger than 10 min., topic set.
    }
      if Token <> RPL_LISTEND then
      begin
        ChannelName := cmdmiddle;
        params[0] := copy(CmdAllParams,pos(':',CmdAllParams)+1,length(CmdAllParams));
        params[1] := trim(copy(CmdAllParams,1,pos(':',CmdAllParams) -1));
        if isnumeric(params[1]) = false then params[1] := '0';
        if assigned(FOnChannelList) then FOnChannelList(self, ChannelName,params[0],strtoint(params[1]), false);
        exit;
      end;
      if assigned(FOnChannelList) then
         FOnChannelList(self, '','',0,true);
      exit;
    end;

    250..255,
    260..266,
    370..376:
    begin { motd stuff again }
      if Token = 004 then
      begin
        FCurrentServer := received;
        for j := 0 to 2 do
        delete(FCurrentServer,1,pos(' ',FCurrentServer));
        delete(FCurrentServer,pos(' ',FCurrentServer),length(FCurrentServer));
        FCurrentServer := trim(FCurrentServer);
      end;

     If Assigned(FOnMotdDisplay) Then
       begin
         if Token <> 376 then FOnMotdDisplay(self, cmdAllParams, false)
         else             FOnMotdDisplay(self, cmdAllParams, true);  // End of /motd
         Exit;
       end;
    end;

    ERR_CHANNELISFULL,
    ERR_INVITEONLYCHAN,
    ERR_BANNEDFROMCHAN,
    ERR_BADCHANNELKEY:
    begin

      // not allowed to join thendesired channel

      if Assigned(FOnCannotJoin) then
       FOnCannotJoin(self, CmdFrom, CmdMiddle, cmdTo, CmdAllParams);

    end;


    -1: begin
        { This command is unimplemented }
        exit;
        end;
  end; { end case }
end;


procedure TVortex.OnSocketDataAvailable(Sender: TObject; Error: Word);
Var
  received : string;
begin
  received := trim(TVortexSocket(sender).ReceiveStr);

  if (IrcOptions.FIgnoreColor) then { if we want to ignore color codes }
  genericparser(StripCc(received))
  else genericparser(received);
End;

procedure TVortex.OnvortexIRCError (Sender: TObject);
Var       Error : word;
Begin
  Error := FClientSocket.LastError;
  {label1.caption := WsockeTOnErrorDesc(LastError);}

  { winsock error 10057 }
  {if error = 10057 then
  FClientSocket.OnDataAvailable := OnConnectDataAvailable;}

  If Assigned(FOnError) Then
  FOnError(sender,error);
End;

procedure TVortex.OnVortexBgException(Sender: TObject; E: Exception;  var CanClose: boolean);
Begin
  If Assigned(FBgException) Then
     FBgException(sender,E,Canclose);
End;

procedure TVortex.OnSocketClosed (Sender: TObject; Error: Word);
Begin
  FConnected := False;
  If Assigned(FAfterDisconnect) Then
     FAfterDisconnect(self);
End;

procedure TVortex.OnSocketConnected (Sender: TObject; Error: Word);
Begin
{ 4.1.3 User message | Only used during Authentications
        Command: USER
        Parameters: <username> <hostname> <servername> <realname>
}

  If Assigned(FAfterConnect) Then
     FAfterConnect(self);

  FConnected := True;
  with FIrcOptions,
       TVortexSocket(Sender) do
  begin

{    SetUserName  := RealName;
    SetUserIdent := User;
    SetUserNick  := NickName;}

    SendStr(Format('USER %s %s %s :%s' + CrLf,
            [lowercase(GetUserNick),GetUserIdent,localiplist[0], FUserName]));

    SendStr(Format('NICK :%s' + CrLf,
            [GetUserNick]));

  end;
End;


function TVortex.LocalIP(num : byte) : string;
Begin
  Try
   Result := LocalIpList[num];
   Except
    Try
      Result := LocalIpList[0];
    Except
  {$IFDEF MSWINDOWS}
      MessageBox(0,'No IP!','error.',mb_ok);
  {$ELSE}
      ShowMessage('Error: No IP!');
  {$ENDIF}
   End;
  End;
End;

procedure TVortex.Joined(Nickname, ChannelName, HostName : string);
var
Channel : TChannels;
i       : integer;
begin

  if ansisametext(Nickname, FIRCOptions.GetUserNick) then
    begin

      // this is me, store channel info in channels list

      Channel := TChannels.Create;
      FChannels.AddObject(ChannelName, Channel);
      with Channel do
      begin
        SetChannelName(ChannelName);
        SetChannelID(FChannels.Count);
      end;

      If Assigned(FAfterJoined) Then
         FAfterJoined(self, ChannelName);

    end
  else
    begin

      // this is NOT me, add Nickname to names-list if channel is in my channels-list

      for i := 0 to FChannels.Count - 1 do
        if (FChannels.Objects[i] <> nil) and
           (TChannels(FChannels.Objects[i]).GetChannelName = ChannelName) then
          begin
            TChannels(FChannels.Objects[i]).AddUserToChannel(Nickname);
            break;
          end;

      If Assigned(FOnUserJoin) Then
         FOnUserJoin(self, Nickname, HostName, ChannelName);

    end;

end;

function TVortex.UserInChannel(nickname, channelname : string) : boolean;
var i : integer;
begin

  i := FChannels.IndexOf(ChannelName);

  Result := (i <> -1) and TChannels(FChannels[i]).UserInCurrentChannel(nickname);

end;

procedure TVortex.Parted(Nickname, HostName, UserName, ChannelName, Reason: string);
var myChannel : integer;
begin

  myChannel := FChannels.IndexOf(ChannelName);

  if ansisametext(Nickname, FIRCOptions.GetUserNick) then
    begin

      // we have left the channel

      // drop the channel from channels-list
      if myChannel <> -1 then
        begin
          TChannels(FChannels.Objects[FChannels.IndexOf(ChannelName)]).Free;
          FChannels.Delete(FChannels.IndexOf(ChannelName));
        end;

      if Assigned(FAfterParted) Then
         FAfterParted(self, ChannelName);

    end
  else
    begin

      // someone else has left the channel

      if myChannel <> -1 then
        TChannels(FChannels.Objects[myChannel]).RemoveUserFromChannel(NickName);

      If Assigned(FOnUserPart) then
         FOnUserPart(self, Nickname,HostName,ChannelName,reason);

    end;

end;

procedure TVortex.Quited(Nickname, user, host, reason: string);
var x : integer;
begin

  if ansisametext(Nickname, FIRCOptions.GetUserNick) then
    begin

      // we have quit

      for x := 0 to FChannels.Count - 1 do
        begin
          TChannels(FChannels[x]).Free;
        end;

      FChannels.Clear;
      // senseless ???

    end
  else
    begin

      // someone else has quit

      for x := 0 to FChannels.Count - 1 do
        begin
          if TChannels(FChannels.Objects[x]).UserInCurrentChannel(NickName) then
            TChannels(FChannels.Objects[x]).RemoveUserFromChannel(NickName);
        end;

      If Assigned(FOnUserQuit) Then
        FOnUserQuit(self, NickName, user, host, Reason);

    end;
end;

procedure TVortex.Kicked(Victim, BOFH, ChannelName, Reason: string);
var myChannel : integer;
begin

  myChannel := FChannels.IndexOf(ChannelName);

  if ansisametext(Victim, FIRCOptions.GetUserNick) then
    begin

      // we have been kicked
      if myChannel <> -1 then
        begin
          TChannels(FChannels.Objects[FChannels.IndexOf(ChannelName)]).Free;
          FChannels.Delete(FChannels.IndexOf(ChannelName));
        end;

      if Assigned(FAfterKicked) then
        FAfterKicked(self, BOFH, ChannelName, Reason);

    end
  else
    begin

      // somebody else has been kicked
      if myChannel <> -1 then
        TChannels(FChannels.Objects[myChannel]).RemoveUserFromChannel(Victim);

      If Assigned(FOnUserKick) Then
        FOnUserKick(self, Victim, BOFH, ChannelName, Reason);

    end;

end;

procedure TVortex.NamesChan(ChannelName, CommaNicks: string;
  EndOfNames: boolean);
var
temp : string;
i : integer;

begin
  if EndOfNames then
  begin
    If Assigned(FOnNamesList) Then
       FOnNamesList(self, 'End of /Names',channelName, True);
    exit;
  end;

  temp := CommaNicks;
  Delete(Temp,1, Pos(':',temp));

  { Replace spaces with commatas }
  If (Length(Temp) > 0) Then
      For I:=0 To Length(Temp) Do
      If (Temp[I] = ' ') Then Temp[I] := ',';

  i := FChannels.IndexOf(ChannelName);
  if i <> -1 then
  TChannels(FChannels.Objects[i]).AddUsersFromCommaText(CommaNicks);

  If Assigned(FOnNamesList) Then
    FOnNamesList(self, temp, ChannelName, false);

end;

procedure TVortex.ChannelTopic(ChannelName, UserName, Topic  : string);
var
i : Integer;
begin

  If Assigned(FOnUserTopic) Then
  FOnUserTopic(self, ChannelName, UserName, Topic);

  i := FChannels.IndexOf(ChannelName);
  if i <> -1 then
  with TChannels(FChannels.Objects[i]) do
  begin
    { bug in VortexChannels. :( }
    SetTopic(Topic);
    SetTopicSetBy(UserName);
  end;

end;

procedure TVortex.ChannelTopicSetBy(ChannelName, Nickname  : string);
var
i : Integer;
begin
  i := FChannels.IndexOf(ChannelName);
  if i <> -1 then
  with TChannels(FChannels.Objects[i]) do
  SetTopicSetBy(NickName);
end;

procedure TVortex.NickChange(OldNick, Newnick: string);
var x : integer;
begin

  if assigned(FBeforeNickChange) then
    if FBeforeNickChange(self, Oldnick, Newnick) = True then Exit;

  for x := 0 to FChannels.Count - 1 do
    begin

      if TChannels(FChannels.Objects[x]).UserInCurrentChannel(OldNick) then
        begin
          TChannels(FChannels.Objects[x]).SetNewUserName(OldNick, NewNick);
        end;

    end;

  if ansisametext(OldNick, FIRCOptions.GetUserNick) then
    begin

      SetMyNick(NewNick);

      if Assigned(FAfterNickChanged) then
        FAfterNickChanged(self, OldNick, NewNick);

    end
  else
    begin

      if Assigned(FOnUserNickChange) Then
        FOnUserNickChange(self, OldNick, NewNick);

    end;

end;

procedure TVortex.SetMyNick(Nickname: string);
begin

  { This one does NOT change your NickName on IRC }
  FIrcOptions.SetUserNick := NickName;

end;

procedure TVortex.SetCurrentServer(Value: string);
begin
  { Which server we are currently connected to }
  FCurrentServer := Value;
end;

procedure TVortex.SetIRCName(Value: string);
begin

  FIrcOptions.FUserName := Value;

end;

procedure TVortex.SetIRCPort(Value: string);
begin
  FIrcOptions.FServerPort := Value;
end;

procedure TVortex.SetMyUserName(Value: string);
begin
  FIrcOptions.SetUserNick := Value;
end;

procedure TVortex.SetVersionInfo(Info: string);
begin
  FCtcpOptions.FVersionReply := info;
end;


//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//                                                                          //
//                     !!! ChannelName & Private messages !!!               //
//       probably the biggest part of vortex is the message handling.       //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////

{
  There are different types of PRIVMSGs:
  :NickName!ident@host.com PRIVMSG To :SomeTextHere

  Now "To" can either be your current NickName, then it's aprivate message
  or a ChannelName name then it's a ChannelName message.
  If The PRIVMSG was a CTCP then "SomeTextHere" begins and ends with char #1.
  Again CTCPs can be sent to individuals or to channels
  Some CTCPs have a really stupid formatting sicne they append the NickName of
  after the trailing #1
  In this case we can safely ignore "NicknameItComesFrom" sicne it's alos passed
  as :NickName!ident@...
}
procedure TVortex.Messages (Line, NickName, host, user, destination, Content : string);
begin
  {
    Is it a CTCP-Message ?
    A third parameter "Dest" was added so that the user-assigned event-handler
    can destinguish between CTCPs sent directly to the user and
    CTCPs sent to a whole ChannelName.
  }

  If (Content[1] = #1) Then
  Begin
    CTCPMessage(Line,NickName,Host,User,Destination,Content);
    exit;
  end;

  { Is this a ChannelName message ? }
  if Destination[1] = '#' Then
  Begin
    If Assigned(FOnChannelmsg) Then
       FOnChannelmsg(self, Destination, Content, NickName, User, host);
    Exit;
  End;

  { Ok this must be a private Message :-) }
  if Assigned(FOnPrivmsg) then
     FOnPrivmsg(self, NickName,User,Host,Content);
end;


procedure TVortex.CTCPMessage(Line, NickName, host, user, destination,
  Content: string);
var
i : integer;
streng : string;
temp   : string;
params : array[0..5] of string;

begin
  streng := Content;
  {
    Strip of the leading #10 char and the trailing
    #10 char including everything that comes behind it
  }
  Delete(Streng,1,1);
  If (Length(Streng) > 0) Then
  Begin
    I:=Pos(#1,Streng);
    If (I = 0) Then I := Length(Streng) + 1;
    Streng := Copy(Streng,1,I-1);
  End;

  {
    Check if it's an action
    If ((Length(cmdAllParams) > 6) and (UpperCase(Copy(cmdAllParams,1,6)) = 'ACTION')) Then
  }
  If ansisametext(copy(streng,1,6),'ACTION') Then
  Begin
    delete(content,1,pos(' ',content));
    If Assigned(FIrcAction) Then
       FIrcAction(self, NickName,Content,Destination);
    Exit;
  End;

 {
   Handle Dccs Here
   If ((Length(Streng) > 3) and (UpperCase(Copy(cmdAllParams,1,3)) = 'Dcc')) Then
 }
 If UpperCase(Copy(streng,1,3)) = 'DCC' Then
  Begin
    temp := streng;

    { if the client send a file with spaces.. }
    if pos('"',temp) <> 0 then
    begin
      Line := between(temp,'"','" ') ;
      delete(temp,pos('"',temp), length(line) +3);
    end else
    begin
      Line := temp;
      for i := 0 to 1 do
      delete(line,1,pos(' ',line));
      delete(line,pos(' ',line),length(line));
      delete(temp,9,length(line)+1);
    end;


    for i := 0 to 5 do
    begin { Find out what type of Dcc we received...  }
        params[i] := trim(copy(temp,1,pos(' ',temp)));
        delete(temp,1,pos(' ',temp));
    end;
      params[5] := temp; { port }

//////////////////////////////////////////////////////////////////////////////
//////////////// when receiving a Dcc chat request ///////////////////////////
//////////////////////////////////////////////////////////////////////////////

  if ansisametext(params[1],'chat') then
  begin
    delete(temp,1,pos(#32,temp));
    params[0] := trim(copy(temp,1,pos(#32,temp)));
    delete(temp,1,pos(#32,temp));
    if params[3] = '0' then { might be a bad idea   }
       params[3] := host;

    { Dcc CHAT chat ip [temp = port] }
    if assigned(FdccChatIncoming) then
    FdccChatIncoming(self, NickName, temp, shortip(params[2]));
    exit;
  end;

//////////////////////////////////////////////////////////////////////////////
//////////////// when receiving a Dcc RESUME request /////////////////////////
//////////////////////////////////////////////////////////////////////////////

  if trim(lowercase(params[1])) = 'resume' then
  begin
    exit;
  end;

//////////////////////////////////////////////////////////////////////////////
//////////////// User accepted your resume request ///////////////////////////
//////////////////////////////////////////////////////////////////////////////

  if lowercase(params[1]) = 'accept' then
  begin
    { Getting the last information we need to make a connection }
    for i := 1 to 2 do
    begin
      params[i] := trim(copy(temp,1,pos(#32,temp)));
      delete(temp,1,pos(#32,temp));
    end;

  {
      params[3] := trim(CmdAllParams);
      params[4] := trim(copy(cmdAllParams,1,pos('"',cmdAllParams)-1));
  }
    if params[4] = '' then
       params[4] := 'file.ext';

    If assigned(FDccGetResume) then
       FDccGetResume(self, NickName, Params[4],temp,params[3]);
    exit;
  end;

//////////////////////////////////////////////////////////////////////////////
//////////////// when receiving a Dcc Send request ///////////////////////////
//////////////////////////////////////////////////////////////////////////////
  if ansisametext(params[1],'send') then
  begin
    {
       Might need a try loop here
       NickName port address filename FileSize
       Some clients sends the entire path. damn!
    }
    if pos ('/',Line) <> 0 then delete(Line,1,Lastdelimiter('/',Line));
    if pos ('\',Line) <> 0 then delete(Line,1,Lastdelimiter('\',Line));
    if assigned(FDccGet) then
       FDccGet(self, NickName,params[3],shortip(params[2]),Line,Params[5]);
      exit;
  end;

End;  { End of Dcc stuff.. }

  {
    Ok it's *no* Dcc request and *no* Action -> fire a CTCP event
    The only *standart* CTCP we handle here is PING - this is required by the standart
    Everything else should be handled by the user-assigned eventhandler imho
    The CTCP event will still be fired though - since clients wnat to rect on this event
  }
  with FCtcpOptions do
  if FReplyToCtcp = true then
  begin
  If ((Length(streng) > 4) and (UpperCase(Copy(streng,1,4)) = 'PING')) Then
  begin
    CtcpReply(NickName,streng);
    exit;
  end;

  If ((Length(streng) >= 7) and (UpperCase(Copy(streng,1,7)) = 'VERSION')) Then
  begin
    CtcpReply(NickName,'VERSION ' + GetVersionInfo);
    exit;
  end;

  If ((Length(streng) >= 6) and (UpperCase(Copy(streng,1,6)) = 'FINGER')) Then
  begin
    with FCtcpOptions do
    CtcpReply(NickName,'FINGER ' + FingerReply);
    exit;
  end;

  If ((Length(streng) >= 4) and (UpperCase(Copy(streng,1,4)) = 'TIME')) Then
  begin
    with FCtcpOptions do
    begin
      if FTimeReply = '' then
      CtcpReply(NickName,'TIME ' + timetostr(now))
      else
      CtcpReply(NickName,'TIME ' + FTimeReply);
    end;
    exit;
  end;

  { Please leave this line intact... :-) }
  If ((Length(streng) >= 10) and (UpperCase(Copy(streng,1,10)) = 'CLIENTINFO')) Then
  begin
    with FCtcpOptions do
    CtcpReply(NickName,FClientInfo);
    exit;
  end;

  { Now fire the CTCP-event handler }
  If Assigned(FOnUserCTCP) Then
  FOnUserCTCP(self, NickName, streng, Destination);
  end;
end;

function TVortex.GetChannelTopic(value: string): string;
var
i : Integer;
begin
  if (value <> '') and
     (value[1] = '#') then { mulig bug fiks }

  i := FChannels.IndexOf(value);
  if i <> -1 then
  with TChannels(FChannels.Objects[i]) do
  begin
    result := GetTopic;
    exit;
  end;

  Result := 'unknown ChannelName';
end;

procedure TVortex.ClearUsersInChannel(value: string);
var
i : Integer;

begin
  if value = '' then
  exit;

  i := FChannels.IndexOf(value);
  if i <> -1 then
  with TChannels(FChannels.Objects[i]) do
  begin
    ClearUsers;
    Quote(format('names %s',[value]));
  end;

end;

function TVortex.GetTopicSetBy(value: string): string;
var
i : Integer;

begin
  i := FChannels.IndexOf(value);
  if i <> -1 then
  with TChannels(FChannels.Objects[i]) do
  begin
    result := GetTopicSetBy;
    Exit;
  end;

  Result := 'unknown ChannelName';
end;

function TVortex.GetUsersFromChannel(Value: string): string;
var
i : integer;

begin
  i := FChannels.IndexOf(value);
  if i <> -1 then
  with TChannels(FChannels.Objects[i]) do
  begin
    result := GetAllNicksFromChannel;
    Exit;
  end;

  Result := 'unknown ChannelName';
end;

function TVortex.CountUsersFromChannel(Value: string): integer;
var
i : integer;

begin
  i := FChannels.IndexOf(value);
  if i <> -1 then
  with TChannels(FChannels.Objects[i]) do
  begin
    result := CountUsers;
    Exit;
  end;

   Result := 0;

end;

{ I put these on one line since they wont be modified anyway }
procedure TVortex.SetIrcOptions(const Value: TIrcOptions);begin  FIrcOptions.Assign(Value);end;
procedure TVortex.SetCtcpOptions(const Value: TCtcpOptions);begin  FCtcpOptions.Assign(Value);end;
procedure TVortex.SetSocksOptions(const Value: TSocksOptions);begin  FSocksOptions.Assign(Value);end;
procedure TVortex.SetAuthOptions(const Value: TAuthOptions);begin  FAuthOptions.Assign(Value);end;
procedure TCtcpOptions.Assign(Source: TPersistent);begin  inherited;end;
procedure TAuthOptions.Assign(Source: TPersistent);begin  inherited;end;
procedure TIrcOptions.Assign(Source: TPersistent);begin  inherited;end;


{ incomplete }
procedure TVortex.InitDccGet(NickName, port, address, filename,
  filesize: string);
begin

end;

procedure TVortex.InitDccGetResume(NickName, port, Position: string);
begin

end;


procedure TVortex.SayAction(destination, content: string);
begin
  Say(destination,format(#1 + 'ACTION %s' + #1,[content]));
end;

{ incomplete }
procedure TVortex.lookup(dns: string);
begin


  // self.lookup(dns);
  // oh no! will result in endless loop

end;

procedure TVortex.ChannelMode(NickName, ChannelName, NewMode, Params : string);
var activateMode : boolean;
    x : integer;
    i : integer;

begin

  i := FChannels.IndexOf(ChannelName);
    if i = -1 then exit;

  // !!! hint: !!!
  // some modes do have params, some do not

  for x := 1 to length(NewMode) do
    begin

      case NewMode[x] of
      // activators
      '+' : activateMode := true;
      '-' : activateMode := false;

      // modes
//      't' : TChannels(FChannels.Objects[i]).set             // only ops set topic
//      'p' : TChannels(FChannels.Objects[i]).set             // private channel
//      'm' : TChannels(FChannels.Objects[i]).set             // moderated
//      'n' : TChannels(FChannels.Objects[i]).set             // no external messages
      'k' : if activateMode then                              // key
              TChannels(FChannels.Objects[i]).SetPassword(StripNextParam(Params))
            else
              TChannels(FChannels.Objects[i]).SetPassword('');
//      'i' : TChannels(FChannels.Objects[i]).set             // invite only
//      's' : TChannels(FChannels.Objects[i]).set             // secret
      'l' : if activateMode then                              // limt of users
              TChannels(FChannels.Objects[i]).SetLimit(StrToInt((StripNextParam(Params))))
            else
              TChannels(FChannels.Objects[i]).SetLimit(0);
      end;
    end;
end;

procedure TVortex.UserMode(Nickname, ChannelName, Victim, NewMode: string);
var activateMode : boolean;
    x : integer;
    i : integer;
begin

  i := FChannels.IndexOf(ChannelName);
    if i = -1 then exit;

  for x := 1 to length(NewMode) do
    begin
      case NewMode[x] of
      '+' : activateMode := true;
      '-' : activateMode := false;
      'o', 'v' : begin
                   TChannels(FChannels.Objects[i]).SetUserMode(StripNextParam(Victim), NewMode[x], activateMode);
                 end;
      end;

    end;

end;

function TVortex.StripNextParam(var aParams: string): string;
begin

  if aParams = '' then
    begin
      Result := '';
      exit;
    end;

  if pos(' ', aParams) <> 0 then
    begin

      Result := copy(aParams, 1, pos(' ', aParams));
      Delete(aParams, 1, pos(' ',aParams));

    end
  else
    begin
      Result := aParams;
      aParams := '';
    end;


end;

{ TAuthOptions }

procedure TAuthOptions.OnIdentDserverSessionAvailable(Sender: TObject;
  Error: Word);
var
AuthClient : TVortexSocket;

begin
  { uferdig }
  AuthClient := TVortexSocket.Create(nil);

  With AuthClient do
  begin
    LineMode := TRUE;
    HSocket  := TVortexSocket(sender).Accept;
 { We are answering on Identd requests}
    if FAnswer = true then
           SendStr(format('%s, 113 : USERID : %s : %s' + crlf,['6667', FSystem, FIdent]))
      else SendStr(format('%s, 113 : ERROR : NO-USER'  + crlf,['6667']));
    Close;
  end;

  with TVortex(Pointer(FOwner)) do
  if Assigned(FAuthConnected) then
  FAuthConnected(self);

  DeleteObjects(AuthClient);
end;

procedure TAuthOptions.StartAuth;
 { experimental IdentD daemon }
begin
  if FAuthServer <> nil then FAuthServer.free;
  FAuthServer := TVortexSocket.Create(nil);
  with FAuthServer do
  try
    OnSessionAvailable := OnIdentDserverSessionAvailable;
    Addr  := '0.0.0.0';
    port  := '113';
    proto := 'tcp';
    listen;
  except
    { something wrong happened here }
    Free;
  end;
end;

procedure TAuthOptions.StopAuth;
begin
  if Assigned(FAuthServer) then
  FAuthServer.close;
end;

procedure TIrcOptions.SetNotifyList(const Value: TStringlist);
begin
  FNotifyList.assign(Value);
end;


End.
