-- Lander Auto Typer
-- STATIC DEOBFUSCATION / ANALYSIS OUTPUT
-- The supplied wrapper was analyzed without executing its payload.
--
-- The wrapper has two main layers:
--   1. A custom 64-character / 6-bit string decoder.
--   2. A small virtualized dispatcher that reconstructs and calls functions
--      through computed table keys.
--
-- The original source-level variable names and control flow cannot be
-- recovered exactly from this wrapper alone without executing/emulating
-- the custom VM. The code below extracts the readable first-stage logic.

local encoded = {
    "fTxhRkXMuJf4RTfM",
    "TkNUfTD+fNe5",
    "NW61R+XmAzJ5Vu6Fq+J+oC==",
    "4+6sP+NkfDl7RNTx5c2aNWmeAMDK0JhTAFSi+uMOo+6mqFSWPNk/aufD4R==",
    "RNNT5Jpe5DqeNET=", "qcM2qR==",
    "BWpmqt6FAzDYqd==", "0cMS0l==",
    "NFNg4EpO4JpR5FXouJ6MRd==",
    "atfFAUQ1P/Kd647XnUTYo5KJPsCFPZ6my8p/y+eFAzMkqR==",
    "65h2", "5EDn4Jpefl==", "0+xdy+6r", "uJpSBzfDVl==",
    "4tfFAE0D0l==", "nTDFBvCZ6+SMTEMxfZy=", "0WM/ad==",
    "qcNFqcNY0C==", "uFA=",
    "uFSR5cMF5uqW6JSkn+NfoZQ20/lJfMemRDm8AT0Y0sK=",
    "uJpvyd==", "5WMYqWNjR+XFoUl=",
    "atfFAto3PjpjyuAYqcDFatN80u6DAz61BvfDBvRYycp2PFXmBzfDAsMzyue2ou6sAzDd0to15WMYqWNjPTMJ0Ww2Rcpkq4JTVuhDA8pjq+q/PcmDy+f/PcJma+715WMYqWNjuFMJ0WpbNtDdquebNsoY0tmF",
    "TJNg5TDTuJ6MRJeMNl==", "TZfmAD6sAzDd0t6UBcxza+A=",
    "uJpIq+7=", "5TDnuJqh5MNM",
}

-- The original code reverses these ranges before decoding.
local function reverse_range(t, first, last)
    while first < last do
        t[first], t[last] = t[last], t[first]
        first = first + 1
        last = last - 1
    end
end

reverse_range(encoded, 1, 27)
reverse_range(encoded, 1, 23)
reverse_range(encoded, 24, 27)

-- Custom character -> 6-bit mapping.
local alphabet = {
    J=53,j=50,a=26,H=62,Z=55,m=33,f=17,O=15,v=39,
    ["7"]=56,W=6,M=5,["8"]=34,Y=46,k=36,U=3,e=9,p=61,
    ["5"]=19,["/"]=51,["1"]=47,d=48,["6"]=13,s=35,V=30,
    R=16,["0"]=29,t=7,L=59,G=10,["9"]=63,K=8,B=27,X=49,
    z=38,n=14,D=37,P=11,["+"]=22,x=57,h=1,T=20,b=31,u=23,
    o=12,["3"]=58,A=28,w=60,S=41,C=32,["4"]=18,["2"]=45,
    F=52,E=4,c=54,l=0,y=24,r=43,g=2,q=25,i=42,I=44,N=21,Q=40
}

local function decode_string(value)
    local output = {}
    local accumulator = 0
    local count = 0

    for position = 1, #value do
        local character = value:sub(position, position)
        local six_bit = alphabet[character]

        if six_bit then
            accumulator = accumulator + six_bit * 64 ^ (3 - count)
            count = count + 1

            if count == 4 then
                count = 0

                output[#output + 1] = string.char(
                    math.floor(accumulator / 65536),
                    math.floor((accumulator % 65536) / 256),
                    accumulator % 256
                )

                accumulator = 0
            end

        elseif character == "=" then
            output[#output + 1] =
                string.char(math.floor(accumulator / 65536))

            if position >= #value
                or value:sub(position + 1, position + 1) ~= "=" then
                output[#output + 1] =
                    string.char(math.floor((accumulator % 65536) / 256))
            end

            break
        end
    end

    return table.concat(output)
end

-- Decode the first layer into a separate table.
local decoded = {}

for index, value in ipairs(encoded) do
    if type(value) == "string" then
        decoded[index] = decode_string(value)
    else
        decoded[index] = value
    end
end

----------------------------------------------------------------------
-- SECOND STAGE: CUSTOM DISPATCHER
----------------------------------------------------------------------

-- The remainder of the supplied script is not conventional Lua source.
-- It creates aliases for environment functions, maintains reference
-- counters, constructs a table of computed keys, and uses a state variable
-- as a dispatcher.
--
-- Important states visible in the supplied code:
--
--     15933201
--     1564643
--     8900341
--     9802941
--     1232436
--
-- The wrapper also constructs computed keys in the range -40009 .. -39983
-- and resolves them through a function equivalent to:
--
--     key = string_table[index + 40010]
--
-- This is characteristic of a virtualized / flattened control-flow layer.
--
-- The final call has the conceptual form:
--
--     execute_virtual_machine(environment, unpack, newproxy,
--                             setmetatable, getmetatable, select, ...)
--
-- The exact original Lua source cannot be reconstructed statically from
-- the pasted wrapper alone because the VM instruction semantics are encoded
-- in the dispatcher and its decoded constants.
--
-- No decoded payload is executed by this file.

return decoded
