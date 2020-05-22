
class NewNet_FlakShell extends FlakShell
	HideDropDown
	CacheExempt;

var PlayerController PC;
var vector DesiredDeltaFake;
var float CurrentDeltaFakeTime;
var bool bInterpFake;
var bool bOwned;

var FakeProjectileManager FPM;

struct ReplicatedRotator
{
    var int Yaw;
    var int Pitch;
    var int Roll;
};

struct ReplicatedVector
{
    var float X;
    var float Y;
    var float Z;
};

const INTERP_TIME = 0.50;

replication
{
    unreliable if(bDemoRecording)
       DoMove, DoSetLoc;
}

simulated function DoMove(Vector V)
{
    Move(V);
}

simulated function DoSetLoc(Vector V)
{
    SetLocation(V);
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();
    if(Level.NetMode!=NM_Client)
        return;

    PC = Level.GetLocalPlayerController();
    if (CheckOwned())
        CheckForFakeProj();
}

simulated function bool CheckOwned()
{
    if(class'UTComp_Settings'.default.bEnableEnhancedNetCode==false)
        return false;
    bOwned = (PC!=None && PC.Pawn!=None && PC.Pawn == Instigator);
    return bOwned;
}

simulated function bool CheckForFakeProj()
{
     local Projectile FP;

     if(FPM == none)
        FindFPM();
     FP = FPM.GetFP(class'NewNet_Fake_FlakShell');
     if(FP != none)
     {
      //  bInterpFake=true;
         DesiredDeltaFake = Location - FP.Location;
         doSetLoc(FP.Location);
         FPM.RemoveProjectile(FP);
         bOwned=False;
         return true;
     }
     return false;
}

simulated function FindFPM()
{
    foreach DynamicActors(class'FakeProjectileManager', FPM)
        break;
}


simulated function Tick(float deltatime)
{
    super.Tick(deltatime);
    if(Level.NetMode != NM_Client)
        return;
    if(bInterpFake)
        FakeInterp(deltatime);
    else if(bOwned)
        CheckForFakeProj();
}

simulated function FakeInterp(float dt)
{
    local vector V;
    local float OldDeltaFakeTime;

    V=DesiredDeltaFake*dt/INTERP_TIME;

    OldDeltaFakeTime = CurrentDeltaFakeTime;
    CurrentDeltaFakeTime+=dt;

    if(CurrentDeltaFakeTime < INTERP_TIME)
        Domove(V);
    else // (We overshot)
    {
        DoMove((INTERP_TIME - OldDeltaFakeTime)/dt*V);
        bInterpFake=False;
        //Turn off checking for fakes
    }
}




defaultproperties
{
}
