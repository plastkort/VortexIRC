unit VortexChannels;

interface

uses classes, SysUtils, vortexcommon;

  type TUsers = TList;

  type TUser = class(TObject)
  private
     Nick : string;
     Op : boolean;
     Voice : boolean;
  public
     function getNickName : string;
     function isOped : boolean;
     function isVoiced : boolean;

     procedure setNickName(aNickName : string);
     procedure setOp(aOped : boolean);
     procedure setVoice(aVoiced : boolean);
  end;

{
  Type TUser = class
  private
    FNickList : Tstringlist;
    FVoiced   : boolean;
    FOped     : boolean;
  public
    property IsVoiced : Boolean read FVoiced;
    property IsOped : boolean read FOped;
  end;
}

  type TChannels = class(TObject)
  private
    FChannelName  : string;
    FChannelTopic : String;
    FTopicSetBy   : String;
    FKeyPasswd    : string;
    FUsers        : TUsers;
    FInviteOnly   : Boolean;
    FOnlyOpTopic  : Boolean;
    FExternalMsg  : Boolean;
    FPrivate      : Boolean;
    FSecret       : Boolean;
    FLimit        : Boolean;
    FKey          : Boolean;
    FModerated    : Boolean;
    FLimitNum     : integer;
    FChannelType  : Char;
    FChannelID    : integer;
  public
    Constructor Create;
    Destructor Destroy; override;
    Procedure SetTopic (NewTopic : string);
    Procedure SetTopicSetBy (NickName : string);
    Procedure SetChannelName (ChannelName : string);
    Procedure SetPassword (Password : string);
    Procedure SetLimit (Value : Integer);
    Procedure SetChannelID (ID : Integer);
    Procedure SetChannelType (Value : Char);
    procedure AddUsersFromCommaText(var users: string);
    procedure AddUserToChannel(user : string);
    procedure RemoveUserFromChannel (user : string);
    procedure SetNewUserName(OldName, NewName : string);
    procedure DeleteUsers;
    procedure ClearUsers;
    function  CountUsers : integer;
    function  GetAllNicksFromChannel : string;
    function  UserInCurrentChannel(user: string): boolean;
    procedure FillListOfUsers(aList : TStrings);
    procedure SetUserMode(Username : string; Mode : char; active : boolean);
  published
    property GetChannelType     : Char   read FChannelType;
    property GetChannelName     : string read FChannelName;
    property GetTopic           : string read FChannelTopic;
    property GetTopicSetBy      : string read FChannelTopic;
    property GetModeKeyPassword : string read FKeyPassWd;
    property GetModeNumLimit    : integer read FLimitNum;
    property IsInviteOnly       : boolean read FInviteOnly;
    property IsOnlyOpsSetTopic  : boolean read FOnlyOpTopic;
    property IsPrivate          : boolean read FPrivate;
    property IsSecret           : boolean read FSecret;
    property IsLimitedTo        : boolean read FLimit;
    property IsKey              : boolean read FKey;
    property IsModerated        : boolean read FModerated;
    property IsNoExternalMessages : boolean read FExternalMsg;
end;


function ListSort(Item1, Item2 : pointer) : integer;

implementation

uses math;


function ListSort(Item1, Item2 : pointer) : integer;
var Priority1, priority2 : integer;
begin

  // sort ops (@) on top, then voices (+) then the rest
  if TUser(Item1).isOped then
    Priority1 := 1
  else if TUser(Item1).isVoiced then
    Priority1 := 2
  else
    Priority1 := 3;

  if TUser(Item2).isOped then
    Priority2 := 1
  else if TUser(Item2).isVoiced then
    Priority2 := 2
  else
    Priority2 := 3;

  Result := CompareValue(Priority1, Priority2);

  // priority is same, sort by name in alphabetical order (CAPS are ignored)
  if Result = 0 then
    Result := CompareText(TUser(Item1).getNickName, TUser(Item2).getNickName);

end;

  { TChannels }

constructor TChannels.Create;
begin
  inherited create;
  FUsers := TList.Create;
end;

destructor TChannels.Destroy;
begin
  FUsers.Free;
  inherited destroy;
end;

procedure TChannels.SetChannelID(ID: Integer);
begin
  FChannelID := ID;
end;

procedure TChannels.SetChannelName(ChannelName: string);
begin
  FChannelName := ChannelName;
end;

procedure TChannels.SetLimit(Value: Integer);
begin
  FLimitNum := Value;
end;

procedure TChannels.SetPassword(Password: string);
begin
  FKeyPassWd := Password;
end;

procedure TChannels.SetTopic(NewTopic: string);
begin
  FChannelTopic := NewTopic;
end;

procedure TChannels.SetTopicSetBy(NickName: string);
begin
  FTopicSetBy := NickName;
end;

procedure TChannels.SetChannelType(Value: Char);
begin
  FChannelType := value;
end;

procedure TChannels.AddUsersFromCommaText(var users: string);
var
list  : Tstringlist;
User : TUser;
x : integer;
Nick : string;

begin
  { Convert spaces to commas...}
  while Pos(' ', users) > 0 do
  users[Pos(' ', users)] := ',';

  { creates a list of commausers...}
  list := Tstringlist.create;
  with list do
  begin
    CommaText := users;
    try

      for x := 0 to List.Count - 1 do
        begin
          Nick := List[x];

          User := TUser.Create;

          if Nick[1] = '@' then
            User.setOp(true);

          if Nick[1] = '+' then
            User.setVoice(true);

          if Nick[1] in ['@', '+'] then
            System.Delete(Nick, 1, 1);

          User.setNickName(Nick);

          FUsers.Add(User);
        end;
    except
    end;
  end;
  list.Free;
  FUsers.Sort(@ListSort);
end;

procedure TChannels.AddUserToChannel(user: string);
var NewUser : TUser;
begin

  NewUser := TUser.Create;

  if user[1] = '@' then
    NewUser.setOp(true);

  if user[1] = '+' then
    NewUser.setVoice(true);

  if user[1] in ['@', '+'] then
    System.Delete(user, 1, 1);

  NewUser.setNickName(user);
  FUsers.Add(NewUser);

  FUsers.Sort(@ListSort);

end;

function TChannels.UserInCurrentChannel(user: string) : boolean;
var x : integer;
begin

  Result := false;

  for x := 0 to FUsers.Count - 1 do
    begin

      if TUser(FUsers[x]).getNickName = user then
        begin
          Result := true;
          exit
        end;
    end;
end;

procedure TChannels.RemoveUserFromChannel(user: string);
var x : integer;

begin

  if user[1] in ['@', '+'] then
    System.Delete(user, 1, 1);

  for x := FUsers.Count - 1 downto 0 do
    if TUser(FUsers[x]).getNickName = user then
      begin
        TUser(FUsers[x]).Free;
        FUsers.Delete(x);
      end;

end;

function TChannels.CountUsers: integer;
begin

  result := FUsers.Count;

end;

procedure TChannels.DeleteUsers;
var x : integer;
begin

  for x := 0 to FUsers.Count - 1 do
    TUser(FUsers[x]).Free;

  FUsers.Clear;

end;

procedure TChannels.ClearUsers;
begin

  FUsers.Clear;

end;


function TChannels.GetAllNicksFromChannel: string;
var
    x : integer;
begin

  Result := '';

  for x := 0 to FUsers.count - 2 do
    begin

      if TUser(FUsers[x]).isOped then
        // op-sign
        Result := Result + '@'
      else if TUser(FUsers[x]).isVoiced then
        // voice-sign
        Result := Result + '+';

      Result := Result + TUser(FUsers[x]).getNickName + ',';

    end;

  Result := Result + TUser(FUsers[FUsers.Count - 1]).getNickName;

end;

procedure TChannels.FillListOfUsers(aList: TStrings);
var x : integer;
    Pre : string;
begin

  aList.Clear;

  for x := 0 to FUsers.Count - 1 do
    begin
      Pre := '';

      if TUser(FUsers[x]).isOped then
        // op-sign
        Pre := '@'
      else if TUser(FUsers[x]).isVoiced then
        // voice-sign
        Pre := '+';

      aList.Add(Pre + TUser(Fusers[x]).getNickName);
    end;

end;

procedure TChannels.SetNewUserName(OldName, NewName: string);
var x : integer;
begin

  for x := 0 to FUsers.Count - 1 do
    begin
      if TUser(FUsers[x]).getNickName = OldName then
        begin
          // set new nickname of user, modes will be still present
          TUser(FUsers[x]).setNickName(NewName);
          exit;
        end;
    end;
  FUsers.Sort(@ListSort);
end;

procedure TChannels.SetUserMode(Username: string; Mode: char;
  active: boolean);
var x : integer;
begin

  for x := 0 to Fusers.Count do
    begin

      if ansisametext(TUser(FUsers[x]).getNickName, Username) then
        case Mode of
        // mode 'o' = op, mode 'v' = voice
        // just add more modes in irc character here if neccessary
        'o' : TUser(FUsers[x]).setOp(active);
        'v' : TUser(FUsers[x]).setVoice(active);
        end;

      exit;

    end;
end;

{ TUser }

function TUser.getNickName: string;
begin

  Result := Nick;

end;

function TUser.isOped: boolean;
begin

  Result := Op;

end;

function TUser.isVoiced: boolean;
begin

  Result := Voice;

end;

procedure TUser.setNickName(aNickName: string);
begin

  Nick := aNickName;

end;

procedure TUser.setOp(aOped: boolean);
begin

  OP := aOped;

end;

procedure TUser.setVoice(aVoiced: boolean);
begin

  Voice := aVoiced;

end;

end.

