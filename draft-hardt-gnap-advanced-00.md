---
docname: draft-hardt-gnap-advanced-01
title: The Grant Negotiation and Authorization Protocol - Advanced Features
date: 2020-07-04
category: std
ipr: trust200902
area: Security
consensus: true

author:
    ins: D. Hardt
    organization: SignIn.Org
    role: editor
    name: Dick Hardt
    email: dick.hardt@gmail.com
    country: United States

normative:

  RFC2119:
  RFC4949:

  GNAP:
    title: The Grant Negotiation and Authorization Protocol
    target: https://tools.ietf.org/html/draft-hardt-xauth-protocol
    date: June 6, 2020
    author:
      -
        ins: D. Hardt


informative:



--- abstract 

TBD

--- middle

# Introduction

This document includes additional features for the Grant Negotiation and Authorization Protocol (GNAP) {{GNAP}}, and presumes familiarity and knowledge of GNAP.


**Terminology**

This document uses the following terms defined in {{GNAP}}:

+ authN
+ authZ
+ Authorization
+ Authorization URI (AZ URI)
+ Claim
+ Client
+ Registered Client
+ Grant
+ Grant Server (GS)
+ Grant URI
+ Grant Request
+ Grant Response
+ GS URI
+ Interaction
+ NumericDate
+ Resource Owner (RO)
+ Resource Server (RS)
+ User


**Notational Conventions**

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT",
"SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this
specification are to be interpreted as described in {{RFC2119}}.

Certain security-related terms are to be understood in the sense
defined in {{RFC4949}}.  These terms include, but are not limited to,
"attack", "authentication", "authorization", "certificate",
"confidentiality", "credential", "encryption", "identity", "sign",
"signature", "trust", "validate", and "verify".

Unless otherwise noted, all the protocol parameter names and values
are case sensitive. 

Some protocol parameters are parts of a JSON document, and are referred to in JavaScript notation. For example, foo.bar refers to the "bar" boolean attribute in the "foo" object in the following example JSON document:

    {
        "foo" : {
            "bar": true
        }
    }



# Grant Management APIs

In addition to creating and reading a Grant as specified in GNAP The Client MAY list, update, delete, and discover a Grant. 


## List Grants {#ListGrants}

The Client MAY list the Grants provided to the Client by doing an a GET on the GS URI. The GS MUST respond with a list of Grant URIs \[ format TBD] or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

## Update Grant {#UpdateGrant}

The Client updates a Grant by doing an HTTP PUT of a JSON document to the corresponding Grant URI.

The JSON document MUST include the following from the {{GNAP}} Grant Request JSON:

+ iat
+ uri set to the Grant URI

and MAY include the following from the {{GNAP}} Grant Request JSON:

+ user
+ interaction
+ authorization or authorizations
+ claims

The GS MUST respond with one of the standard GNAP responses (Grant Response, Interaction Response, Wait Response) or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

Following is a non-normative example where the Client wants to update the Grant Request with additional claims:


    { 
        "iat"       : 15790460234,
        "uri"       : "https://as.example/endpoint/grant/example3",
        "claims": {
            "oidc": {
                "userinfo" : {
                    "email"          : { "essential" : true },
                    "name"           : { "essential" : true },
                    "picture"        : null
                }
            }
        }
    }


## Delete Grant {#DeleteGrant}


The Client deletes a Grant by doing an HTTP DELETE of the corresponding Grant URI.

The GS MUST respond with OK 200, or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.


##  Grant Options {#GrantOptions}

The Client can get the supported operations for a Grant by doing an HTTP OPTIONS of the corresponding Grant URI.

The GS MUST respond with the supported methods 

\[Format TBD]

or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

# Authorization Management APIs

In addition to reading an Authorization as specified in {{GNAP}}, The Client MAY update, delete, and discover an Authorization. 

## Update Authorization {#UpdateAuthZ}

The Client updates an Authorization by doing an HTTP PUT to the corresponding AZ URI of the following JSON. All of the following MUST be included.

+ **iat** - the time of the request as a NumericDate.

+ **uri** - the AZ URI.

+ **authorization** - the new authorization requested per the {{GNAP}} Grant Request JSON "authorization" object.

The GS MUST respond with a GNAP Authorization JSON document, or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

## Delete Authorization {#DeleteAuthZ}

The Client deletes an Authorization by doing an HTTP DELETE to the corresponding AZ URI.

The GS MUST respond with OK 200, or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

A GS MAY indicate support for this feature by including the "DELETE" method in the AZ URI OPTIONS response.

## Authorization Options {#AuthZOptions}


The Client can get the supported operations for an Authorization by doing an HTTP OPTIONS of the corresponding AZ URI.

The GS MUST respond with the supported methods 

\[Format TBD]


or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.



# Reciprocal Grant

Party A and Party B both want to obtain a Grant from the other party. Each party will be both Client and GS. This would require two complete GNAP flows with an awkward redirect between them, and the User may have to authenticate multiple times as context is lost. Reciprocal Grant simplifies the User experience.

In the following sequence, steps 1 - 7 & 9 are a standard GNAP sequence. 

                  Party A                            Party B
                 +--------+                         +--------+
                 |        |                         |        |
                 | Client |--(1)-- Create Grant A ->|   GS   |
                 |        |                         |        |
                 | Client |<--- Interaction ---(2)--|   GS   |
                 |        |      Response           |        |
                 |        |                         |        |
                 | Client |--(3)--- Read Grant A -->|   GS   |       +---+
                 |        |                         |        |       | U |
                 | Client |--(4)--- Interaction --- | - - -  | ----->| s |
                 |        |          Transfer       |        |       | e |
                 |        |                         |   GS   |<-(5)->| r |
                 |        |                         |        | authN |   |
                 |        |                         |   GS   |<-(6)->|   |
                 |        |                         |        | authZ |   |
                 | Client |<------- Grant A ---(7)--|   GS   |       +---+
                 |        |        Response         |        |
                 |        |                         |        |
                 |   GS   |<- Create Grant B --(8)--| Client |
    +---+        |        |   user.reciprocal       |        |
    | U |        |        |                         |        |
    | s |<------ | - - -  | --- Interaction --(9)---|   GS   |
    | e |        |        |     Transfer            |        |
    | r |<-(10)->|   GS   |                         |        |
    |   | AuthZ  |        |                         |        |
    +---+        |   GS   |--(11)-- Grant B ------->| Client |
                 |        |         Response        |        |
                 +--------+                         +--------+

1. **Create Grant A** Party A makes a Create Grant request to the Party B GS URI.

2. **Interaction Response**  Party B returns an interaction response containing the Grant A URI.

3. **Read Grant A** Party A does an HTTP GET of the Grant A URI. 

4. **Interaction Transfer** Party A transfers User interaction to the Party B.

5. **User Authentication** Party B authenticates the User.

6. **User Authorization** If required, Party B interacts with the User to determine which identity claims and/or authorizations in the Grant A Request are to be granted.

7. **Create GrantB** Party B creates its Grant B Request with user.reciprocal set to the Grant A URI that will be in the step (2) Grant A Response, and sends it with an HTTP POST to the Party A GS URI. This enables Party A to correlate the Grant B Request and its Grant and the User.

8. **Grant S Response** Party B responds to Party A's Create Grant A Request with a Grant A Response.

9. **Interaction Transfer** Party B redirects the User to the Completion URI at Party A.

10. **User Authorization** If required, Party A interacts with the User to determine which identity claims and/or authorizations in Party B's Grant B Request are to be granted.

11. **Grant B Response** Party A responds with the Grant B Response.


+ **reciprocal** - a new attribute of the {{GNAP}} Request JSON user object. MUST be set to a Grant URI.


# GS Initiated Grant {#GSInitiatedGrantSeq}

The User is at the GS, and wants to interact with a Registered Client. The Client has previously configured an initiation_uri at the GS, and the Grant it requires. 

In this sequence, the GS creates a Grant and redirects the User to the Client's initiation_uri passing a Grant URI:

    +--------+                                  +-------+         +------+
    | Client |                                  |  GS   |         | User |
    |        |                                  |       |<--(1)-->|      |
    |        |                                  |       |         |      |
    |        |<----- GS Initiation Redirect --- | - - - | --(2)---|      |
    |   (3)  |                                  |       |         |      |
    | verify |--(4)--- Read Grant ------------->|       |         +------+
    |        |                                  |       |
    |        |<--------- Grant Response --(5)---|       |
    |        |                                  |       |
    +--------+                                  +-------+


1. **User Interaction** The GS interacts with the User to determine the Client and what identity claims and / or authorizations to provide. The GS creates a Grant and corresponding Grant URI.

2. **GS Initiated Redirect** The GS redirects the User to the Client's initiation_uri, adding a query parameter with the name "grant_uri" and the value being the URL encoded Grant URI.

3. **Client Verification** The Client verifies the Grant URI starts with a GS URI from a GS the Client trusts.

4. **Read Grant** The Client does an HTTP GET of the Grant URI.

5. **Grant Response** The GS responds with a Grant Response.

+ **initiation_uri** - a URI at the Client that contains no query or fragment. How the GS learns the Client initiation_uri and require Grant is out of scope of this document. 


# User Exists

The Client may want to provide a different experience to the User depending on if a User already exists at the GS. By including one or more identifiers in the Grant Request user.identifiers object, and setting user.exists to true, the GS MAY include a user.exists attribute in a GNAP Interaction Response. The value is true if the GS has a user with one or more of the Client provided identifers, and false if not.

+ **exists** - a new attribute of the "user" object. If present in a GNAP Grant Request, it MUST be set to true. 

A GS indicates support for this feature by returning the features.user_exists attribute in the GS Options response set to true.

# Multiple Interactions

There are situations where the Client can not, or prefers not, to ask for all identity claims and/or authorizations it requires. 

In this example sequence, the Client requests an identity claim to determine who the User is. Once the Client learns who the User is, the Client updates the Grant for additional identity claims which the GS prompts the User for and returns to the Client. Once those additional claims are received, the Client updates the Grant with the remaining identity claims required.

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Create Grant ----------->|       |
    |        |         multi = true             |       |
    |        |                                  |       |
    |        |<--- Interaction Response ---(2)--|       |
    |        |         multi = true             |       |
    |        |                                  |       |
    |        |--(3)--- Read Grant ------------->|       |         +------+
    |        |                                  |       |         | User |
    |        |--(4)--- Interaction Transfer --- | - - - | ------->|      |
    |        |                                  |       |         |      |
    |        |                                  |       |<--(5)-->|      |
    |        |                                  |       |  authN  |      |
    |        |<--------- Grant Response ---(6)--|       |         |      |
    |  (7)   |                                  |       |         |      |
    |  eval  |--(8)--- Update Grant ----------->|       |         |      |
    |        |         multi = true             |       |<--(9)-->|      |
    |        |                                  |       |  authZ  |      |
    |        |<--------- Grant Response --(10)--|       |         |      |
    |        |           multi = true           |       |
    |  (11)  |                                  |       |         |      |
    |  eval  |--(12)-- Update Grant ----------->|       |         |      |
    |        |         multi = false            |       |<--(13)->|      |
    |        |                                  |       |  authZ  |      |
    |        |                                  |       |         |      |
    |        |<--- Interaction Transfer --(14)- | - - - | --------|      |
    |        |                                  |       |         |      |
    |        |<--------- Grant Response --(15)--|       |         +------+
    |        |           multi = false          |       |
    |        |                                  |       |
    +--------+                                  +-------+

1. **Create Grant** The Client creates a Grant Request (CreateGrant) including an identity claim and interaction.global.multi set to true, and sends it with an HTTP POST to the GS GS URI.

2. **Interaction Response**  The GS sends an Interaction Response containing the Grant URI and an interaction object, and interaction.global.multi set to true.

3. **Read Grant** The Client does an HTTP GET of the Grant URI.

4. **Interaction Transfer** The Client transfers User interaction to the GS.

5. **User Authentication** The GS authenticates the User.

6. **Grant Response** The GS responds with a Grant Response including the identity claim from User authentication and interaction.global.multi set to true.

7. **Grant Evaluation** The Client queries its User database and does not find a User record matching the identity claim. 

8. **Update Grant** The Client creates an Update Grant Request {{UpdateGrant}} including the initial identity claims required and interaction.global.multi set to true, and sends it with an HTTP PUT to the Grant URI.

9. **User AuthN** The GS interacts with the User to determine which identity claims in the Update Grant Request are to be granted.

10. **Grant Response** The GS responds with a Grant Response including the identity claims released by the User and interaction.global.multi set to true.

11. **Grant Evaluation** The Client evaluates the identity claims in the Grant Response and determines the remaining User identity claim required. 

12. **Update Grant** The Client creates an Update Grant Request {{UpdateGrant}} including the remaining required identity claims and interaction.global.multi set to false, and sends it with an HTTP PUT to the Grant URI.

13. **User AuthZ** The GS interacts with the User to determine which identity claims in the Update Grant Request are to be granted.

14. **Interaction Transfer** The GS transfers User interaction to the Client.

15. **Grant Response** The GS responds with a Grant Response including the identity claims released by the User and interaction.global.multi set to false.

+ **multi** - a new boolean attribute of the GNAP interaction.global object.

A GS indicates support for this feature by returning the features.interaction_multi attribute in the GS Options response set to true.


# Error Responses {#ErrorResponses}

+ TBD


# Acknowledgments

TBD

# IANA Considerations


TBD

# Security Considerations

TBD

--- back

# Document History

## draft-hardt-gnap-advanced-00
- Initial version

## draft-hardt-gnap-advanced-01
- renamed verb to method

# GS API Table

Below is a consolidated table of GS APIs from {{GNAP}} and this document:

| request            | http method | uri          | response     
|:---                |---          |:---          |:--- 
| Create Grant       | POST        | GS URI       | interaction, wait, or grant 
| List Grants        | GET         | GS URI       | grant list
| Verify Grant       | PATCH       | Grant URI    | grant 
| Read Grant         | GET         | Grant URI    | wait, or grant 
| Update Grant       | PUT         | Grant URI    | interaction, wait, or grant 
| Delete Grant       | DELETE      | Grant URI    | success 
| Read AuthZ         | GET         | AZ URI       | authorization 
| Update AuthZ       | PUT         | AZ URI       | authorization 
| Delete AuthZ       | DELETE      | AZ URI       | success 
| GS Options         | OPTIONS     | GS URI       | metadata 
| Grant Options      | OPTIONS     | Grant URI    | metadata 
| AuthZ Options      | OPTIONS     | AZ URI       | metadata  