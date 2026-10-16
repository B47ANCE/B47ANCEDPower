B47ANCEDPower={}
dofile("src/B47ANCEDPower/42/media/lua/shared/B47ANCEDPower/StatusSnapshot.lua")
local snapshot=assert(B47ANCEDPower.StatusSnapshot.fromDiagnostics({providers={source={count=2},storage={count=3},load={count=4},network={count=1}},
    events={historyCount=5,failures={a={count=2},b={count=1}}}}))
assert(#snapshot.rows==6 and snapshot.rows[1].id=="source" and snapshot.rows[1].count==2)
assert(snapshot.rows[6].id=="failures" and snapshot.rows[6].count==3 and snapshot.rows[6].warning)
assert(B47ANCEDPower.StatusSnapshot.fromDiagnostics({})==nil,"malformed diagnostics must fail closed")
local validated=assert(B47ANCEDPower.StatusSnapshot.validate(snapshot)); assert(validated~=snapshot and validated.rows[1]~=snapshot.rows[1])
assert(B47ANCEDPower.StatusSnapshot.validate({schemaVersion=1,rows={{id="bad id",count=1}}})==nil,"invalid transport rows must fail closed")
print("test_status_snapshot.lua: PASS")
