unit VortexCommon;
{ misc procedures and functions for use with vortex.
  StripCc was not made by me (joepezt)
  StripCc is used to remove annoying colorcodes from IRC lines.
  label1.caption := StripCc(Content); from IRC privmsg}

interface
  uses wsocket;

  type TVortexSocket = class ({$IFDEF MSWINDOWS} TWSocket {$ELSE} TIcsSocket {$ENDIF} )
  end;

  function IsNumeric( Value:String ):Boolean;
  function StripCc(Line : string):string;
//  function ShortIP(const LongIP: Cardinal): AnsiString;
//  function LongIP(ShortIP: AnsiString): Cardinal;
  procedure DeleteObjects(var Obj);

implementation

uses SysUtils;

procedure DeleteObjects(var Obj);
var
  MyObject : TObject;
begin
  MyObject := TObject(Obj);
  Pointer(Obj) := nil;
  MyObject.Free;
end;

function IsNumeric( Value:String ):Boolean;
var
    Code : Integer;
    Tmp  : Integer;
begin
    Val ( Value, tmp, Code );
    Result := Code = 0;
end;

function ShortIP(const LongIP: Cardinal): AnsiString;
begin
  Result := Format('%d.%d.%d.%d',[LongIP shr $18,(LongIP shr $10) and $FF,(LongIP shr $08) and $FF, LongIP and $FF]);
end;

function LongIP(ShortIP: AnsiString): Cardinal;
var 
  p, 
  t: PAnsiChar; 
  s: AnsiString; 
  function GrabByte: Byte; 
  begin 
    Result := 0; 
    if (p^ in ['0'..'9']) then 
    begin 
      t := p; 
      while (p^ in ['0'..'9']) do 
        Inc(p); 
      SetString(s, t, p - t); 
      Result := StrToIntDef(s, 0); 
    end else 
      raise EConvertError.CreateFmt('Cannot convert ''%s'' into a longip dword, number expected', [ShortIP]); 
  end; 
  procedure GrabDot; 
  begin 
    if (p^ = '.') then 
      Inc(p) 
    else 
      raise EConvertError.CreateFmt('Cannot convert ''%s'' into a longip dword, dot (.) not found', [ShortIP]); 
  end; 
begin 
  p := PAnsiChar(ShortIP); 
  Result := GrabByte shl $18; 
  GrabDot; 
  Result := (GrabByte shl $10) or Result; 
  GrabDot; 
  Result := (GrabByte shl $08) or Result; 
  GrabDot; 
  Result := GrabByte or Result; 
end;



function StripCc(Line : string):string;
var
  Token : string;
  i,StringLength,ColorCode : integer;

  function StrRemove(str:string;substr:string):string;
  begin
    while pos(substr,str) > 0 do
    delete(str,pos(substr,str),length(substr));
    result := str;
  end;

begin
  Token := Line;
  Token := StrRemove(Token,''); // Bold
  Token := StrRemove(Token,''); // Underline
  Token := StrRemove(Token,''); // Reverse
  Token := StrRemove(Token,''); // Plain
  while pos('',Token) > 0 do
  begin
    i := pos('',Token);
    StringLength := 1;
    if StrToIntDef(copy(Token,i+1,1),-1) > -1 then
    begin
      StringLength := StringLength+1;
      ColorCode := StrToInt(copy(Token,i+1,1));
      if ((ColorCode < 2) and (StrToIntDef(copy(Token,i+2,1),-1) > -1)) then
      begin
        StringLength := StringLength+1;
        if copy(Token,i+3,1) = ',' then
        begin
          StringLength := StringLength+1;
          if StrToIntDef(copy(Token,i+4,1),-1) > -1 then
          begin
            StringLength := StringLength+1;
            ColorCode := StrToIntDef(copy(Token,i+4,1),-1);
            if ((ColorCode < 2) and (StrToIntDef(copy(Token,i+5,1),-1) > -1)) then
              StringLength := StringLength+1
          end;
        end;
      end else
      if copy(Token,i+2,1) = ',' then
      begin
        StringLength := StringLength+1;
        if StrToIntDef(copy(Token,i+3,1),-1) > -1 then
        begin
          StringLength := StringLength+1;
          ColorCode := StrToIntDef(copy(Token,i+3,1),-1);
          if ((ColorCode < 2) and (StrToIntDef(copy(Token,i+4,1),-1) > -1)) then
          StringLength := StringLength+1
        end;
      end;
    end;
    Delete(Token,i,StringLength);
  end;
  result := Token;
end;


end.
 