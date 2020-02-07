---
docname: draft-hardt-xauth-protocol-02
title: The XAuth Protocol
date: 2020-02-05
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

  RFC3966:
  RFC5322:
  RFC5646:
  RFC6749:
  RFC6750:
  RFC7515:
  RFC7516:
  RFC7519:
  RFC7540:
  RFC8259:
  RFC8446:

  OIDC:
    title: OpenID Connect Core 1.0
    target: https://openiD.net/specs/openiD-connect-core-1_0.html
    date: November 8, 2014
    author:
      -
        ins: N. Sakimora
      -
        ins: J. Bradley
      -
        ins: M. Jones
      -
        ins: B. de Medeiros
      -
        ins: C. Mortimore

  OIDC4IA:
    title: OpenID Connect for Identity Assurance 1.0
    target: https://openid.net/specs/openid-connect-4-identity-assurance-1_0.html
    date: October 15, 2019
    author:
      -
        ins: T. Lodderstedt
      -
        ins: D. Fett



informative:

  RFC7049:
  RFC8252:
  RFC8152:
  RFC8323:
  RFC8628:

  browser based apps:
    title: OAuth 2.0 for Browser-Based Apps 
    target: https://tools.ietf.org/html/draft-ietf-oauth-browser-based-apps-04
    date: September 22, 2019
    author:
      -
        ins: A. Parecki
      -
        ins: D. Waite    
  
  RAR:
    title: OAuth 2.0 Rich Authorization Requests 
    target: https://tools.ietf.org/html/draft-ietf-oauth-rar-00
    date: January 21, 2020
    author:
      -
        ins: T. Lodderstedt
      -
        ins: J. Richer
      -
        ins: B. Campbell

  W3C VC:
    title: Verifiable Credentials Data Model 1.0
    target: https://w3c.github.io/vc-data-model/
    date: November 26, 2019
    author:
      - 
        ins: M. Sporny
      - 
        ins: G. Noble
      - 
        ins: D. Chadwick

  QR Code:
    title: ISO/IEC 18004:2015 - Information technology - Automatic identification and data capture techniques - QR Code bar code symbology specification
    target: https://www.iso.org/standard/62021.html
    date: February 1, 2015

  TxAuth:
    title: Transactional AuthN
    target: https://tools.ietf.org/html/draft-richer-transactional-authz-04
    date: December 13, 2019
    author:
      -
        ins: J. Richer

  UTM: 
    title: UGS Service Supplier Framework for Authentication and AuthN
    target: https://utm.arc.nasa.gov/docs/2019-UTM_Framework-NGSA-TM220364.pdf
    date: September, 2019
    author:
      -
        ins: J. Rios
      -
        ins: I. Smith
      -
        ins: P. Venkatesen

--- abstract 

Client software often desires resources or identity claims that are managed independent of the client. This protocol allows a user and/or resource owner to delegate resource authorization and/or release of identity claims to an authorization server. Client software can then request access to resources and/or identity claims by calling the authorization server. The authorization server acquires consent and authorization from the user and/or resource owner if required, and then returns the authorization and identity claims that were approved. This protocol can be extended to support alternative authorizations, claims, interactions, and client authentication mechanisms.

--- middle

# Introduction

This protocol supports the widely deployed use cases supported by OAuth 2.0 {{RFC6749}} & {{RFC6750}}, and OpenID Connect {{OIDC}}, an extension of OAuth 2.0, as well as other extensions, and other use cases that are not supported, such Grant Requesting multiple authorizations in one request. This protocol also addresses many of the security issues in OAuth 2.0 by having parameters securely sent directly between parties, rather than via a browser redirection. 

The technology landscape has changed since OAuth 2.0 was initially drafted. More interactions happen on mobile devices than PCs. Modern browsers now directly support asymetric cryptographic functions. Standards have emerged for signing and encrypting tokens with rich payloads (JOSE) that are widely deployed.

Additional use cases are now being served with extensions to OAuth 2.0: OpenID Connect added support for authentication and releasing identity claims; {{RFC8252}} added support for native apps; {{RFC8628}} added support for smart devices; and support for {{browser based apps}} is being worked on. There are numerous efforts on adding proof-of-possession to resource access.

This protocol simplifies the overall architectural model, takes advantage of today's technology landscape, provides support for all the widely deployed use cases, and offers numerous extension points. 

While this protocol is not backwards compatible with OAuth 2.0, it strives to minimize the migration effort.

This protocol centers around a Grant, a representation of the user identity claims and/or resource authorizations the GS has granted the Client. The Grant is represented by the Grant URI. The Client can create, retrieve, update, and delete a Grant. 

\[Editor: suggestions on how to improve this are welcome!]

\[Editor: suggestions for other names than XAuth are welcome!]


# Terminology

## Parties

The parties and their relationships to each other:

    +--------+                           +------------+
    |  User  |                           |  Resource  |
    |        |                           | Owner (RO) |
    +--------+                           +------------+
        |      \                       /      |
        |       \                     /       |
        |        \                   /        |
        |         \                 /         |
    +--------+     +---------------+     +------------+
    | Client |---->|     Grant     | _ _ |  Resource  |
    |        |<----|  Server (GS)  |     |   Server   |
    |        |     +---------------+     |    (RS)    |
    |        |-------------------------->|            |
    |        |<--------------------------|            |
    +--------+                           +------------+


- **User** - the person interacting with the Client who has delegated access to identity claims about themselves to the Grant Server (GS), and can authenticate at the GS.

- **Client** - requests a Grant from the GS to access one or more Resource Servers (RSs), and/or identity claims about the User. The Client can create, retrieve, update, and delete a Grant. When a Grant is created, the Client receives from the GS the granted access token(s) for the RS(s), and identity claims about the User. The Client uses an access token to access the RS.  There are two types of Clients: Registered Clients and Dynamic Clients. All Clients have a key to authenticate with the Grant Server. 

- **Registered Client** - a Client that has registered with the GS and has a Client ID to identify itself, and can prove it possesses a key that is linked to the Client ID. The GS may have different policies for what different Registered Clients can request. A Registered Client MAY be interacting with a User.

- **Dynamic Client** - a Client that has not been registered with the GS, and each instance will generate it's own key pair so it can prove it is the same instance of the Client on subsequent requests. A single-page application with no server is an example of a Dynamic Client. A Dynamic Client MUST be interacting with a User.

- **Grant Server** (GS) - manages Grants for access to APIs at RSs and release of identity claims about the User. The GS may require explicit consent from the RO or User to provide these to the Client. An GS may support Registered Clients and/or Dynamic Clients. The GS is a combination of the Authorization Server (AS) in OAuth 2.0, and the OpenID Provider (OP) in OpenID Connect.

- **Resource Server** (RS) - has API resources that require an access token from the GS. Owned by the Resource Owner.

- **Resource Owner** (RO) - owns the RS, and has delegated RS access management to the GS. The RO may be the same entity as the User, or may be a different entity that the GS interacts with independently.

## Reused Terms

- **access token** - an access token as defined in {{RFC6749}} Section 1.4.

- **Claims** - Claims as defined in {{OIDC}} Section 5.

- **Client ID** - a GS unique identifier for a Registered Client as defined in {{RFC6749}} Section 2.2.

- **ID Token** - an ID Token as defined in {{OIDC}} Section 2.

- **NumericDate** - a NumericDate as defined in {{RFC7519}} Section 2.

- **authN** - short for authentication.

- **authZ** - short for authorization.

## New Terms

- **GS URI** - the endpoint at the GS the Client calls to create a Grant. The unique identifier for the GS.

- **Grant** - the user identity claims and/or RS authorizations the GS has granted to the Client.

- **Grant URI**  - the URI that represents the Grant. The Grant URI MUST start with the GS URI.

- **Authorization** - the access granted by the RO to the Client. Contains an access token.

- **AuthZ URI** - the URI that represents the Authorization the Client was granted by the RO. The AuthZ URI MUST start with the GS URI. The AuthZ URI is used to refresh, update, and delete an access token.

- **interaction** - \[Editor: what do we really mean by this term?]



# Sequences

Before any sequence, the Client needs to be manually or programmatically configured for the GS. See GS Options {{GSoptions}} for details.

\[Editor: the plethora of sequences are included to illustrate all the different actions. Many of these could potentially be moved to a use case document in the future.]

## Create Grant {#CreateGrantSeq}

The Client requests a Grant from the GS that requires User interaction:

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Create Grant ----------->|       |
    |        |                                  |  (2)  |
    |        |<--- Interaction Response ---(3)--|  eval |
    |        |                                  |       |
    |        |--(4)--- Read Grant ------------->|       |         +------+
    |        |                                  |       |         | User |
    |        |--(5)--- Interaction Transfer --- | - - - | ------->|      |
    |        |                                  |       |<--(6)-->|      |
    |        |                                  |       |  authN  |      |
    |        |                                  |       |<--(7)-->|      |
    |        |                                  |       |  authZ  |      |
    |        |<--- Interaction Transfer ---(8)- | - - - | --------|      |
    |        |                                  |       |         |      |
    |        |<--------- Grant Response ---(9)--|       |         +------+
    |        |                                  |       |
    +--------+                                  +-------+
 
1. **Create Grant** The Client creates a Grant Request ({{CreateGrant}}) and sends it with an HTTP POST to the GS GS URI.

2. **Grant Request Evaluation**  The GS processes the request to determine if it will send a Interaction Response, Wait Response, or a Grant Response. The GS determines that interaction with the User is required and sends an Interaction Response. (For readability, this step is not described in the following sequences)

3. **Interaction Response**  The GS sends an Interaction Response ({{InteractionResponse}}) containing the Grant URI and an interaction object.

4. **Read Grant** The Client does an HTTP GET of the Grant URI ({{ReadGrant}}).

5. **Interaction Transfer** The Client transfers User interaction to the GS.

6. **User Authentication** The GS authenticates the User.

7. **User Authorization** If required, the GS interacts with the User to determine which identity claims and/or authorizations in the Grant Request are to be granted.

8. **Interaction Transfer** The GS transfers User interaction to the Client.

9. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}).



## Reciprocal Grant

Party A and Party B are both a Client and a GS, and each Client would like a Grant for the other GS. Party A starts off being the Client per Create Grant {{CreateGrantSeq}}. Party B then includes a Reciprocal Request in its Grant Response. Party A then gets authorization from the User and returns a Grant URI to Party B. Party A and B swap roles, and Party B's Client obtains the Grant from Party A's GS.


                    Party A                                    Party B
                   +--------+                                 +--------+
                   | Client |                                 |   GS   |
                   ~ ~ ~ ~ ~ ~     Same as steps 1 - 8 of    ~ ~ ~ ~ ~ ~
    +------+       |        |        Create Grant above       |        |
    | User |       |        |                                 |        |
    |      |<----- | - - -  | -- Interaction Transfer ------- |        |
    |      |       |        |                                 |        |
    |      |       |        |<------- Grant Response ---(1)---|        |
    |      |       |        |      Reciprocal Grant Request   |        |
    |      |<-(2)->|        |                                 |        |
    |      | AuthZ |        |---(3)--- Update Grant --------->|        |
    +------+       |        |   Reciprocal Grant Response     |        |
                   |        |                                 |        |
                   |        |<-- Empty Grant Response ---(4)--|        |
                   |        |                                 |        |
                   +--------+       (5) Swap Roles            +--------+
                   |   GS   |                                 | Client |
                   |        |<------------ Read Grant ---(6)--|        |
                   |        |                                 |        |
                   |        |--(7)--- Grant Response -------->|        |
                   |        |                                 |        |
                   +--------+                                 +--------+



1. **Grant Response** Party B responds with a Grant Response including a Reciprocal Object {{ReciprocalRequest}} requesting its own Grant.

2. **User Authorization** If required, Party A interacts with the User to determine which identity claims and/or authorizations in the Grant Request are to be granted to Party B.

3. **Update Grant** Party A sends an Update Grant request containing the Grant URI in the Reciprocal object {{ReciprocalResponse}}. 

4. **Grant Response** Party B responds with an Empty Grant Response as there were no other requests in the Update Grant.

5. **Swap Roles** Party A now acts as a GS, Party B as a Client.

4. **Read Grant** Party B does an HTTP GET of the Grant URI ({{ReadGrant}}).

9. **Grant Response** Party A responds with a Grant Response ({{GrantResponse}}).


## GS Initiated Grant {#GSInitiatedGrantSeq}

The User is at the GS, and wants to interact with a Registered Client. The GS can redirect the User to the Client:

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


1. **User Interaction** The GS interacts with the User to determine the Client and what identity claims and authorizations to provide. The GS creates a Grant and corresponding Grant URI.

2. **GS Initiated Redirect** The GS redirects the User to the Client's interaction_uri, adding a query parameter with the name "Grant URI" and the value being the URL encoded Grant URI.

3. **Client Verification** The Client verifies the Grant URI is from an GS the Client trusts, and starts with the GS GS URI.

4. **Read Grant** The Client does an HTTP GET of the Grant URI ({{ReadGrant}}).

5. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}).

See {{GSInitiatedGrant}} for more details.

## Create and Update

The Client requests an identity claim to determine who the User is. Once the Client learns who the User is, and the Client updates the Grant for additional identity claims which the GS prompts the User for and returns to the Client. Once those are received, the Client updates the Grant with the remaining identity claims required.

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Create Grant ----------->|       |
    |        |  "interaction"."keep":true       |       |
    |        |                                  |       |
    |        |<--- Interaction Response ---(2)--|       |
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
    |        |  "interaction"."keep":true       |       |<--(9)-->|      |
    |        |                                  |       |  authZ  |      |
    |        |<--------- Grant Response --(10)--|       |         |      |
    |  (11)  |                                  |       |         |      |
    |  eval  |--(12)-- Update Grant ----------->|       |         |      |
    |        |  "interaction"."keep":false      |       |<--(13)->|      |
    |        |                                  |       |  authZ  |      |
    |        |                                  |       |         |      |
    |        |<--- Interaction Transfer --(14)- | - - - | --------|      |
    |        |                                  |       |         |      |
    |        |<--------- Grant Response --(15)--|       |         +------+
    |        |                                  |       |
    +--------+                                  +-------+

1. **Create Grant** The Client creates a Grant Request ({{CreateGrant}}) including an identity claim and "interaction"."keep":true, and sends it with an HTTP POST to the GS GS URI.

2. **Interaction Response**  The GS sends an Interaction Response ({{InteractionResponse}}) containing the Grant URI, an interaction object, and "interaction"."keep":true.

3. **Read Grant** The Client does an HTTP GET of the Grant URI ({{ReadGrant}}).

4. **Interaction Transfer** The Client transfers User interaction to the GS.

5. **User Authentication** The GS authenticates the User.

6. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}) including the identity claim from User authentication and "interaction"."keep":true.

7. **Grant Evaluation** The Client queries its User database and does not find a User record matching the identity claim. 

8. **Update Grant** The Client creates an Update Grant Request ({{UpdateGrant}}) including the initial identity claims required and "interaction"."keep":true, and sends it with an HTTP PUT to the Grant URI.

9. **User AuthN** The GS interacts with the User to determine which identity claims in the Update Grant Request are to be granted.

10. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}) including the identity claims released by the User and "interaction"."keep":true.

11. **Grant Evaluation** The Client evaluates the identity claims in the Grant Response and determines the remaining User identity claim required. 

12. **Update Grant** The Client creates an Update Grant Request ({{UpdateGrant}}) including the remaining required identity claims and "interaction"."keep":false, and sends it with an HTTP PUT to the Grant URI.

13. **User AuthZ** The GS interacts with the User to determine which identity claims in the Update Grant Request are to be granted.

14. **Interaction Transfer** The GS transfers User interaction to the Client.

15. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}) including the identity claims released by the User.


## Create and Delete

The Client requests an identity claim to determine who the User is. Once the Client learns who the User is, and the Client has all the identity claims and authorizations needed, the Client deletes the Grant which prompts the GS to transfer the interaction back to the Client.

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Create Grant ----------->|       |
    |        |  "interaction"."keep":true       |       |
    |        |                                  |       |
    |        |<--- Interaction Response ---(2)--|       |
    |        |                                  |       |
    |        |--(3)--- Read Grant ------------->|       |         +------+
    |        |                                  |       |         | User |
    |        |--(4)--- Interaction Transfer --- | - - - | ------->|      |
    |        |                                  |       |         |      |
    |        |                                  |       |<--(5)-->|      |
    |        |                                  |       |  authN  |      |
    |        |<--------- Grant Response ---(6)--|       |         |      |
    |  (7)   |                                  |       |         |      |
    |  eval  |--(8)--- Delete Grant ----------->|       |         |      |
    |        |<------- Delete Response ---------|       |         |      |
    |        |                                  |       |         |      |
    |        |<--- Interaction Transfer ---(9)- | - - - | --------|      |
    |        |                                  |       |         |      |
    +--------+                                  +-------+         +------+

1. **Create Grant** The Client creates a Grant Request ({{CreateGrant}}) including an identity claim and "interaction"."keep":true, and sends it with an HTTP POST to the GS GS URI.

2. **Interaction Response**  The GS sends an Interaction Response ({{InteractionResponse}}) containing the Grant URI, an interaction object, and "interaction"."keep":true.

3. **Read Grant** The Client does an HTTP GET of the Grant URI ({{ReadGrant}}).

4. **Interaction Transfer** The Client transfers User interaction to the GS.

5. **User Authentication** The GS authenticates the User.

6. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}) including the identity claim from User authentication and "interaction"."keep":true.

7. **Grant Evaluation** The Client queries its User database and finds the User record matching the identity claim, and that no additional claims or authorizations are required. 

8. **Delete Grant** The Client no longer needs the Grant and decides to Delete Grant ({{DeleteGrant}}) by sending an HTTP DELETE to the Grant URI. If the GS responds with success the Grant no longer exists.

## Create, Discover, and Delete

The Client wants to discover if the GS has a User with a given identifier. If not, it will not transfer interaction to the GS.

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Create Grant ----------->|       |
    |        |  "user"."exists":true            |       |
    |        |                                  |       |
    |        |<--- Interaction Response ---(2)--|       |
    |        |     "user"."exists":false        |       |
    |        |                                  |       |
    |        |--(3)--- Delete Grant ----------->|       |
    |        |<------- Delete Response ---------|       |
    |        |                                  |       |
    +--------+                                  +-------+

1. **Create Grant** The Client creates a Grant Request ({{CreateGrant}}) including an identity claim request, a User identifier, and "user"."exists":true. The Client sends it with an HTTP POST to the GS GS URI.

2. **Interaction Response**  The GS sends an Interaction Response ({{InteractionResponse}}) containing the Grant URI, an interaction object, and "user"."exists":false.

3. **Delete Grant** The Client determines the GS cannot fulfil its Grant Request, and decides to Delete Grant ({{DeleteGrant}}) by sending an HTTP DELETE to the Grant URI. If the GS responds with success the Grant no longer exists.



## Create and Wait

The Client wants access to resources that require the GS to interact with the RO, which may not happen immediately, so the GS instructs the Client to wait and check back later.

    +--------+                                  +-------+
    | Client |                                  |  GS   |        
    |        |--(1)--- Create Grant ----------->|       |       
    |        |                                  |       |
    |        |<---------- Wait Response ---(2)--|       |         +------+
    |  (3)   |                                  |       |         |  RO  |
    |  Wait  |                                  |       |<--(4)-->|      |
    |        |                                  |       |  authZ  |      |
    |        |--(5)--- Read Grant ------------->|       |         +------+
    |        |                                  |       |
    |        |<--------- Grant Response --(6)---|       |
    |        |                                  |       |
    +--------+                                  +-------+

1. **Create Grant** The Client creates a Grant Request ({{CreateGrant}}) and sends it with an HTTP POST to the GS GS URI.

2. **Wait Response**  The GS sends an Interaction Response ({{WaitResponse}}) containing the Grant URI and wait time.

3. **Client Waits** The Client waits the wait time.

4. **RO AuthZ** The GS interacts with the RO to determine which identity claims in the Grant Request are to be granted. 

5. **Read Grant** The Client does an HTTP GET of the Grant URI ({{ReadGrant}}).

6. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}).


## Read Grant

The Client wants to acquire fresh identity claims and authorizations in the Grant. No User or RO interaction is required as no new consent or authorization is required.

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Read Grant ------------->|       |
    |        |                                  |       |
    |        |<--------- Grant Response --(2)---|       |
    |        |                                  |       |
    +--------+                                  +-------+

1. **Read Grant** The Client does an HTTP GET of the Grant URI ({{ReadGrant}}).

2. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}) containing updated identity claims and authorizations.

## Access Resource & AuthZ Refresh

The Client has an access token and uses it to access resources at an RS. The access token expires, and the Client acquires a fresh access token from the GS.

    +--------+                             +----------+ 
    | Client |                             | Resource | 
    |        |--(1)--- Access Resource --->|  Server  | 
    |        |<------- Resource Response --|   (RS)   | 
    |        |                             |          | 
    |        |--(2)--- Access Resource --->|          | 
    |        |<------- Error Response -----|          | 
    |        |                             |          | 
    |        |                             +----------+  +-------+
    |        |                                           |  GS   |
    |        |--(3)--- Refresh AuthZ ------------------->|       |
    |        |<------- AuthZ Response -------------------|       |
    |        |                                           |       |
    +--------+                                           +-------+



1. **Resource Request** The Client accesses the RS with the access token per {{RSAccess}} and receives a response from the RS.

2. **Resource Request** The Client attempts to access the RS, but receives an error indicating the access token has expired. 

3. **Refresh AuthZ** If the Client received an AuthZ URI in the Response JSON "authorization" object ({{ResponseAuthorizationObject}}), the Client can Refresh AuthZ ({{RefreshAuthZ}}) with an HTTP GET to the AuthZ URI and receive an Response JSON "authorization" object" ({{ResponseAuthorizationObject}}) with a fresh access token.


## GS API Table

| request            | http verb | uri          | response     
|:---                |---        |:---          |:--- 
| Create Grant       | POST      | GS URI       | interaction, wait, or grant 
| Read Grant         | GET       | Grant URI    | wait, or grant 
| Update Grant       | PUT       | Grant URI    | interaction, wait, or grant 
| Delete Grant       | DELETE    | Grant URI    | success 
| Refresh AuthZ      | GET       | AuthZ URI    | authorization 
| Update AuthZ       | PUT       | AuthZ URI    | authorization 
| Delete AuthZ       | DELETE    | AuthZ URI    | success 
| GS Options         | OPTIONS   | GS URI       | metadata 
| Grant Options      | OPTIONS   | Grant URI    | metadata 
| AuthZ Options      | OPTIONS   | AuthZ URI    | metadata  


\[ Editor: is there value in an API for listing a Client's Grants? eg:]

    List Grants     GET     GS URI    JSON array of Grant URIs


# Grant and AuthZ Life Cycle


**Grant life Cycle**

The Client can create, read, update, and delete Grants. Grants persist until deleted, or another Grant is created for the same GS, Client, and User tuple.

At any point in time, there can only be one Grant for the GS, Client, and User tuple. When a Client creates a Grant at the same GS for the same User, the GS MUST invalidate a previous Grant for the Client at that GS for that User.

**AuthZ Life Cycle**

\[Editor: what is the life cycle of a granted access token and AuthZ URI relative to a Grant? Issued claims will live past the Grant life cycle.]

\[Editor: ]


\[Editor: confirm we can only have one Grant outstanding at a time.]

\[Editor: confirm the GS cannot expire a Grant.]

# GS APIs

**Client Authentication**

All APIs except for GS Options require the Client to authenticate. 

This protocol enables different mechanisms for how the Client authenticates to the GS. See {{ClientAuthN}} for using JOSE client authentication. Extensions may define other mechanisms. \[Editor: reference other documents if they are known]




## Create Grant {#CreateGrant}

The Client creates a Grant by doing an HTTP POST of a JSON {{RFC8259}} document to the GS URI.

The JSON document MUST include the following from the Request JSON {{RequestJSON}}:

+ iat
+ nonce
+ uri set to the GS URI
+ client

and MAY include the following from Request JSON {{RequestJSON}}

+ user
+ interaction
+ authorization or authorizations
+ claims
+ reciprocal

The GS MUST respond with one of Grant Response {{GrantResponse}}, Interaction Response {{InteractionResponse}}, Wait Response {{WaitResponse}}, or one of the following errors:

    TBD

from Error Responses {{ErrorResponses}}.

Following is a non-normative example where the Client wants to interact with the User with a popup and is requesting identity claims about the User and read access to the User's contacts:

    Example 1

    { 
        "iat"       : 15790460234,
        "uri"       : "https://as.example/endpoint",
        "nonce"     : "f6a60810-3d07-41ac-81e7-b958c0dd21e4",
        "client": {
            "display": {
                "name"  : "SPA Display Name",
                "uri"   : "https://spa.example/about"
            }
        },
        "interaction": {
            "type"      : "popup"
        },
        "authorization": {
            "type"      : "oauth_scope",
            "scope"     : "read_contacts"
        },
        "claims": {
            "oidc": {
                "id_token" : {
                    "email"          : { "essential" : true },
                    "email_verified" : { "essential" : true }
                },
                "userinfo" : {
                    "name"           : { "essential" : true },
                    "picture"        : null
                }
            }
        }
    }


Following is a non-normative example where the Client is requesting the GS to keep the interaction with the User after returning the ID Token so the Client can update the Grant, and also asking if the user exists:

    Example 2

    { 
        "iat"       : 15790460234,
        "uri"       :"https://as.example/endpoint",
        "nonce"     :"5c9360a5-9065-4f7b-a330-5713909e06c6",
        "client": {
            "id"        : "di3872h34dkJW"
        },
        "interaction": {
            "keep"      : true,
            "type"      : "redirect",
            "uri"       : "https://web.example/return"
        },
        "user": {
            "identifiers": {
                "email" : "jane.doe@example.com"
            },
            "exists"    : true
        },
        "claims"    : { "oidc": { "id_token" : {} } }
    }


## Read Grant {#ReadGrant}

The Client reads a Grant by doing an HTTP GET of the corresponding Grant URI.

The GS MUST respond with one of Grant Response {{GrantResponse}}, Interaction Response {{InteractionResponse}}, Wait Response {{WaitResponse}}, or one of the following errors:

    TBD

from Error Responses {{ErrorResponses}}.

## Update Grant {#UpdateGrant}

The Client updates a Grant by doing an HTTP PUT of a JSON document to the corresponding Grant URI.

The JSON document MUST include the following from the Request JSON {{RequestJSON}}

+ iat
+ uri set to the Grant URI

and MAY include the following from Request JSON {{RequestJSON}}

+ user
+ interaction
+ authorization or authorizations
+ claims
+ reciprocal

The GS MUST respond with one of Grant Response {{GrantResponse}}, Interaction Response {{InteractionResponse}}, Wait Response {{WaitResponse}}, or one of the following errors:

    TBD

from Error Responses {{ErrorResponses}}.

Following is a non-normative example where the Client made an 'interaction'.'keep:true request, and now wants to update the request with additional claims:

    Example 3

    { 
        "iat"       : 15790460234,
        "uri"       : "https://as.example/endpoint/example.grant",
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

    TBD

from Error Responses {{ErrorResponses}}.

## Request JSON {#RequestJSON}


\[Editor: do we want to reuse the JWT claims "iat","jti", etc.]

+ **iat** - the time of the request as a NumericDate.

+ **nonce** - a unique identifier for this request. Note the Grant Response MUST contain a matching nonce attribute value.

+ **uri** - the GS URI if in a Create Grant {{CreateGrant}}, or the Grant URI if in an Update Grant {{UpdateGrant}}.


### "client" Object
The client object MUST contain either the id attribute for Registered Clients, or the display object for Dynamic Clients.

+ **id** - the Client ID the GS has for the Registered Client.

+ **display** - the display object contains the following attributes:

    + **name** - a string that represents the Dynamic Client

    + **uri** - a URI representing the Dynamic Client 

\[Editor: a max length for the name?]
\[Editor: a max length for the URI?]

The name and uri will be displayed by the GS when prompting for authorization.

### "interaction" Object
The interaction object contains the type of interaction the Client will provide the User. Other attributes 

+ **keep** - a JSON boolean. If set to the JSON value true, the GS will not transfer the User interaction back to the Client after processing the Grant request. The JSON value false is equivalent to the attribute not being present, and the GS will transfer the User interaction back to the Client after processing the request. This attribute is OPTIONAL


    + **type** - contains one of the following values: "popup", "redirect", or "qrcode". Details in {{InteractionType}}. This attribute is REQUIRED.

    + **redirect_uri** - this attribute is REQUIRED if the type is "redirect". It is the URI that the Client requests the GS to redirect the User to after the GS has completed interacting with the User. If the Client manages session state in URIs, then the redirect_uri SHOULD contain that state.

    + **ui_locales** - End-User's preferred languages and scripts for the user interface, represented as a space-separated list of {{RFC5646}} language tag values, ordered by preference. This attribute is OPTIONAL.

\[Editor: do we need max pixels or max chars for qrcode interaction? Either passed to GS, or max specified values here?]

\[Editor: other possible interaction models could be a "webview", where the Client can display a web page, or just a "message", where the client can only display a text message]

\[Editor: we may need to include interaction types for iOS and Android as the mobile OS APIs evolve.]


### "user" Object {#RequestUserObject}

+ **exists** - MUST contain the JSON true value. Indicates the Client requests the GS to return a "user"."exists" value in an Interaction Response {{InteractionResponse}}. This attribute is OPTIONAL, and MAY be ignored by the GS.

+ **identifiers** - REQUIRED if the exists attribute is present. The values MAY be used by the GS to improve the User experience. Contains one or more of the following identifiers for the User:

    + **phone_number** - contains a phone number per Section 5 of {{RFC3966}}.

    + **email** - contains an email address per {{RFC5322}}.

    + **oidc** - is an object containing both the "iss" and "sub" attributes from an OpenID Connect ID Token per {{OIDC}} Section 2.


### "authorization" Object {#AuthorizationObject}

+ **type** - one of the following values: "oauth_scope" or "oauth_rich". This attribute is REQUIRED.

+ **scope** - a string containing the OAuth 2.0 scope per {{RFC6749}} section 3.3. MUST be included if type is "oauth_scope" or "oauth_rich". 

+ **authorization_details** - an authorization_details object per {{RAR}}. MUST be included if type is "oauth_rich".

\[Editor: details may change as the {{RAR}} document evolves]

### "authorizations" Object 

A JSON array of "authorization" objects. Only one of "authorization" or "authorizations" may be in the Request JSON. 

\[Editor: instead of an array, we could have a Client defined dictionary of "authorization" objects]

### "claims" Object {#ClaimsObject}

Includes one or more of the following:

+ **oidc** - an object that contains one or both of the following objects:

    - **userinfo** - Claims that will be returned as a JSON object 

    - **id_token** - Claims that will be included in the returned ID Token. If the null value, an ID Token will be returned containing no additional Claims. 

The contents of the userinfo and id_token objects are Claims as defined in {{OIDC}} Section 5. 

+ **oidc4ia** - OpenID Connect for Identity Assurance claims request per {{OIDC4IA}}.

+ **vc** - \[Editor: define how W3C Verifiable Credentials {{W3C VC}} can be requested.]

### "reciprocal" Object {#ReciprocalResponse}

+ **uri** - the Grant URI for the Reciprocal Grant. This attribute is REQUIRED.

+ **client** - the client object must contain the "id" attribute with the Client ID the Grant was issued to. This attribute is REQUIRED.

+ **authorization** - an authorization object per {{ResponseAuthorizationObject}} in the Response JSON.

+ **authorizations** - an authorizations object per {{ResponseAuthorizationsObject}} in the Response JSON.

+ **claims** - a claims object per {{ResponseClaimsObject}} in the Response JSON.


\[Editor: parameters for the Client to request it wants the Grant Response signed and/or encrypted?]





## Refresh Authorization {#RefreshAuthZ}

The Client updates an Authorization by doing an HTTP GET to the corresponding AuthZ URI.

The GS MUST respond with an Response JSON "authorization" object {{ResponseAuthorizationObject}}, or one of the following errors:

    TBD

from Error Responses {{ErrorResponses}}.

## Update Authorization {#UpdateAuthZ}

The Client updates an Authorization by doing an HTTP PUT to the corresponding AuthZ URI of the following JSON. All of the following MUST be included.

+ **iat** - the time of the response as a NumericDate.

+ **uri** - the AuthZ URI.

+ **authorization** - the new authorization requested per the Request JSON "authorization" object {{AuthorizationObject}}.

The GS MUST respond with an Response JSON "authorization" object {{ResponseAuthorizationObject}}, or one of the following errors:

    TBD

from Error Responses {{ErrorResponses}}.

## Delete Authorization

The Client deletes an Authorization by doing an HTTP DELETE to the corresponding AuthZ URI.

The GS MUST respond with OK 200, or one of the following errors:

    TBD

from Error Responses {{ErrorResponses}}.


## GS Options {#GSoptions}


\[Editor: this section is a work in progress]

The Client may be configured manually by reviewing the GS documentation, or some configuration may occur dynamically using a programmatic discovery mechanism. In addition to GS documentation, the GS MAY provide a metadata document located at:

    <as_uri> + "/.well-known/xauth-configuration"

\[Editor: alternatively, the HTTP OPTIONS method on the GS URI could return all the options. This has the advantage that the Client can authenticate the same way it authenticates for all other GS APIs, and the GS can return Client specific results.]




The Client can get the metadata for the GS by doing an HTTP OPTIONS of the corresponding GS URI.

The GS MUST respond with the the following JSON document:


+ **uri** - the GS URI.


+ **client_authentication** - an array of the Client Authentication mechanisms supported by the GS

+ **interactions** - an array of the interaction types supported by the GS.

+ **authorization** - an object containing the authorizations the Client may request from the GS, if any.

Details TBD

+ **claims** - an object containing the identity claims the Client may request from the GS, if any, and what public keys the claims will be signed with.

Details TBD

+ **algorithms** - a list of the cryptographic algorithms supported by the GS. 

+ **user_exists** - boolean indicating if "user"."exists" is supported.

+ **authentication_list** - boolean indicating if "authorizations" is supported.

or one of the following errors:

    TBD

from Error Responses {{ErrorResponses}}.

##  Grant Options {#GrantOptions}


The Client can get the metadata for the Grant by doing an HTTP OPTIONS of the corresponding  Grant URI.

The GS MUST respond with the the following JSON document:

+ **verbs** - an array of the HTTP verbs supported at the GS URI.




Details TBD

\[Editor: keys used to sign and/or encrypt responses, or decrypt requests]
\[Editor: metadata for extensions]

or one of the following errors:

    TBD

from Error Responses {{ErrorResponses}}.

## AuthZ Options {#AuthZOptions}


The Client can get the metadata for the AuthZ by doing an HTTP OPTIONS of the corresponding AuthZ URI.

The GS MUST respond with the the following JSON document:

+ **verbs** - an array of the HTTP verbs supported at the GS URI.


or one of the following errors:

    TBD

from Error Responses {{ErrorResponses}}.

# GS Initiated Grant {#GSInitiatedGrant}

\[Editor: In OAuth 2.0, all flows are initiated at the Client. If the AS wanted to initiate a flow, it redirected to the Client, that redirected back to the AS to initiate a flow.

Here is a proposal to support GS initiated: authentication; just-in-time (JIT) provisioning; and authorization]

**initiation_uri** A URI at the Client that contains no query or fragment. How the GS learns the Client initiation_uri is out of scope. 


The GS creates a Grant and Grant URI, and redirects the User to the initiation_uri with the query parameter "grant" and the value of Grant URI.

See {{GSInitiatedGrantSeq}} for the sequence diagram.


# GS API Responses





## Grant Response {#GrantResponse}

The Grant Response MUST include the following from the Response JSON {{ResponseJSON}}

+ iat
+ nonce
+ uri
+ expires_in

and MAY include the following from Response JSON {{ResponseJSON}}

+ authorization or authorizations
+ claims
+ reciprocal

Example non-normative Grant Response JSON document for Example 1 in {{CreateGrantSeq}}:

    { 
        "iat"           : 15790460234,
        "nonce"         : "f6a60810-3d07-41ac-81e7-b958c0dd21e4",
        "uri"           : "https://as.example/endpoint/ey7snHGs",
        "expires_in"    : 300
        "authorization": {
            "type"          : "oauth_scope",
            "scope"         : "read_contacts",
            "expires_in"    : 3600,
            "method"        : "bearer",
            "token"         : "eyJJ2D6.example.access.token.mZf9p"
        },
        "claims": {
            "oidc": {
                "id_token"      : "eyJhbUzI1N.example.id.token.YRw5DFdbW",
                "userinfo" : {
                    "name"      : "John Doe",
                    "picture"   : "https://photos.example/p/eyJzdkiO"
                }
            }
        }
    }

Example non-normative Grant Response JSON document for Example 2 in {{CreateGrantSeq}}:

    {
        "iat"   : 15790460234,
        "nonce" : "0d1998d8-fbfa-4879-b942-85a88bff1f3b",
        "uri"   : "https://as.example/endpoint/ey7snHGs",
        "authorization": {
            "type"          : "oauth_scope",
            "scope"         : "read_calendar write_calendar",
            "expires_in"    : 3600,
            "method"        : "pop",
            "token"         : "eyJJ2D6.example.access.token.mZf9p"
            "jwk": {
                "x5u"   : "https://as.example/jwk/VBUEOIQA82" 
            },
            "uri"       : "https://as.example/endpoint/authz/example"
        }
    }


## Interaction Response {#InteractionResponse}

The Interaction Response MUST include the following from the Response JSON {{ResponseJSON}}

+ iat
+ nonce
+ uri
+ interaction

and MAY include the following from Response JSON {{ResponseJSON}}

+ user
+ wait

A non-normative example of an Interaction Response follows:

    {
        "iat"       : 15790460234,
        "nonce"     : "0d1998d8-fbfa-4879-b942-85a88bff1f3b",
        "uri"       : "https://as.example/endpoint/grant/",
        "interaction" : {
            "type"      : "popup",
            "uri"       : "https://as.example/popup/eyskdjaksjk"
        },
        "user": {
            "exists" : true
        }
    }


## Wait Response {#WaitResponse}

The Wait Response MUST include the following from the Response JSON {{ResponseJSON}}

+ iat
+ nonce
+ uri
+ wait

A non-normative example of an Interaction Response follows:

    {
        "iat"       : 15790460234,
        "nonce"     : "0d1998d8-fbfa-4879-b942-85a88bff1f3b",
        "uri"       : "https://as.example/endpoint/grant/",
        "wait"      : 300
    }

## Response JSON {#ResponseJSON}

Details of the JSON document: 

+ **iat** - the time of the response as a NumericDate.

+ **nonce** - the nonce that was included in the Request JSON {{RequestJSON}}.

+ **uri** -

+ **wait** -

+ **expires_in** - a numeric value specifying how many seconds until the Grant expires. This attribute is OPTIONAL.

### "interaction" Object {#interactionObject}

If the GS wants the Client to start the interaction, the GS MUST select one of the interaction mechanisms provided by the Client in the Grant Request, and include the matching attribute in the interaction object: 

+ **type** - this MUST match the type provided by the Client in the Grant Request client.interaction object.

+ **uri** - the URI to interact with the User per the type. This may be a temporary short URL if the type is qrcode so that it is easy to scan. 

+ **message** - a text string to display to the User if type is qrcode.

\[Editor: do we specify a maximum length for the uri and message so that a device knows the maximum it needs to support? A smart device may have limited screen real estate.]


### "user" Object

+ **exists** - a boolean value indicating if the GS has a user with one or more of the provided identifiers in the Request "user"."identifiers" object {{RequestUserObject}}



### "authorization" Object {#ResponseAuthorizationObject}

The "authorization" object is a response to the Request "authorization" object {{AuthorizationObject}}, the Refresh Authorization {{RefreshAuthZ}}, or the Update Authorization {{UpdateAuthZ}}.

+ **type** - the type of claim request: "oauth_scope" or "oauth_rich". See the "type" object in {{AuthorizationObject}} for details. 

+ **scope** - the scopes the Client was granted authorization for. This will be all, or a subset, of what was requested. This attribute is OPTIONAL.

+ **authorization_details** - the authorization details granted per {{RAR}}. Included if type is "oauth_rich".

+ **method** - one of the access mechanisms: "bearer", "jose", or "jose+body". See {{RSAccess}} for details.

+ **token** - the access token for accessing an RS.  This attribute is REQUIRED.

+ **expires_in** - a numeric value specifying how many seconds until the access token expires. This attribute is OPTIONAL.

+ **jwk** - the jwk object to use in a proof-of-possession access method.

+ **uri** - the AuthZ URI. Used to refresh, update, and delete the authorization. This attribute is OPTIONAL. 

### "authorizations" Object {#ResponseAuthorizationsObject}

A JSON array of authorization objects. Support for the authorizations object is OPTIONAL.

### "claims" Object {#ResponseClaimsObject}

The claims object is a response to the Request "claims" object {{AuthorizationObject}}.

+ **oidc**

    - **id_token** - an OpenID Connect ID Token containing the Claims the User consented to be released.
    - **userinfo** - the Claims the User consented to be released.

    Claims are defined in {{OIDC}} Section 5.

+ **oidc4ia** - OpenID Connect for Identity Assurance claims response per {{OIDC4IA}}.

+ **vc**

    The verified claims the user consented to be released. \[Editor: details TBD]

### "reciprocal" Object {#ReciprocalRequest}

The following MUST be included

+ **nonce** - a unique identifier for this request. Note the Grant Response MUST contain a matching nonce attribute value.

+ **client**
    + **id** - the Client ID making the request

One or more of the following objects from the Request JSON {{RequestJSON}} are included:

+ **authorization** {{ResponseAuthorizationObject}}

+ **authorizations** {{ResponseAuthorizationsObject}}

+ **claims** {{ResponseClaimsObject}}

### Interaction Types {#InteractionType}

If the GS wants the Client to initiate the interaction with the User, then the GS will return an Interaction Response. The Client will initiate the interaction with the User in one of the following ways: 

+ **popup**
The Client will create a new popup child browser window containing the "interaction"."uri" attribute. 
\[Editor: more details on how to do this]

The GS will close the popup window when the interactions with the User are complete. 
\[Editor: confirm GS can do this still on all browsers, or does Client need to close] 

+ **redirect**
The Client will redirect the User to the "interaction"."uri" attribute. When the GS interactions with the User are complete, the GS will redirect the User to the "interaction"."redirect_uri" attribute the Client provided in the Grant Request.


+ **qrcode**
The Client will create a {{QR Code}} of the "interaction"."uri" attribute  and display the resulting graphic and the "interaction"."message" attribute as a character string.

An GS MUST support the "popup", "redirect", and "qrcode" interaction types.


### Signing and Encryption


\[Editor: TBD - how response is signed and/or encrypted by the GS]


# RS Access {#RSAccess}



## Access Mechanisms {#AccessMethod}

The are three different mechanisms for the Client to access an RS:

+ **bearer** - the GS provides an access token that the Client presents to access an RS per {{BearerToken}}.

+ **jose** - the GS provides an access handle that the Client presents in a proof-of-possession RS access request per -----.

+ **jose+body** - the Client signs the JSON payload sent to the RS per **POPBody**.

In the Grant Response, the GS will return the method the Client MUST use when accessing the RS.

## Bearer Token {#BearerToken}

## Proof-of-possession

# Error Responses {#ErrorResponses}

    TBD

# JOSE Client Authentication {#ClientAuthN}

How the Client authenticates to the GS and RS are independent of each other. One mechanism can be used to authenticate to the GS, and a different mechanism to authenticate to the RS.

Q: method or mechanism???   


The default mechanism for the Client to authenticate to the GS and the RS is signing a JSON document with JWS per {{RFC7515}}. The resulting tokens always use compact serialization.

It is expected that extensions to this protocol that specify a different mechanism for the Client to authenticate, would over ride this section.

The Authorization Request JSON is signed with JWS and passed as the body of the POST. 

The authorization, refresh, and access handles are signed with JWS resulting in authorization request, refresh, and access tokens respectively. These JOSE tokens are passed in the HTTP Authorization header with the "JOSE" parameter per 

The Client will use the same private key to create all tokens. 

The Client and the GS MUST both use HTTP/2 ({{RFC7540}}) or later, and TLS 1.3 ({{RFC8446}}) or later, when communicating with each other.

\[Editor: too aggressive to mandate HTTP/2 and TLS 1.3?]

## GS Access

## RS Access

## Grant Token

## Grant JSON

## Refresh Token

## Client Public Key Discovery

## JOSE Access Token {#JOSEAccessToken}

## JOSE Request Body


## Request Encryption

## Response Signing and Encryption






** JOSE Tokens

**  JOSE Headers {#JOSEHeaders}

A non-normative example of a JOSE header for a Registered Client using a key id to identify the Client's public key:

    {
        "alg":"ES256",
        "typ":"JOSE",
        "kid":"1"
    }

A non-normative example of a JOSE header for a Registered Client using a certificate to assert the Client's public key:

    {
        "alg":"ES256",
        "typ":"JOSE",
        "jwk":
            {"kty":"RSA",
            "use":"sig",
            "kid":"1b94c",
            "n":"vrjOfz9Ccdgx5nQudyhdoR17V-IubWMeOZCwX_jj0hgAsz2J_pqYW08
            PLbK_PdiVGKPrqzmDIsLI7sA25VEnHU1uCLNwBuUiCO11_-7dYbsr4iJmG0Q
            u2j8DsVyT1azpJC_NG84Ty5KKthuCaPod7iI7w0LK9orSMhBEwwZDCxTWq4a
            YWAchc8t-emd9qOvWtVMDC2BXksRngh6X5bUYLy6AyHKvj-nUy1wgzjYQDwH
            MTplCoLtU-o-8SNnZ1tmRoGE9uJkBLdh5gFENabWnU5m1ZqZPdwS-qo-meMv
            VfJb6jJVWRpl2SUtCnYG2C32qvbWbjZ_jBPD5eunqsIo1vQ",
            "e":"AQAB",
            "x5c":
            ["MIIDQjCCAiqgAwIBAgIGATz/FuLiMA0GCSqGSIb3DQEBBQUAMGIxCzAJB
            gNVBAYTAlVTMQswCQYDVQQIEwJDTzEPMA0GA1UEBxMGRGVudmVyMRwwGgYD
            VQQKExNQaW5nIElkZW50aXR5IENvcnAuMRcwFQYDVQQDEw5CcmlhbiBDYW1
            wYmVsbDAeFw0xMzAyMjEyMzI5MTVaFw0xODA4MTQyMjI5MTVaMGIxCzAJBg
            NVBAYTAlVTMQswCQYDVQQIEwJDTzEPMA0GA1UEBxMGRGVudmVyMRwwGgYDV
            QQKExNQaW5nIElkZW50aXR5IENvcnAuMRcwFQYDVQQDEw5CcmlhbiBDYW1w
            YmVsbDCCGSIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAL64zn8/QnH
            YMeZ0LncoXaEde1fiLm1jHjmQsF/449IYALM9if6amFtPDy2yvz3YlRij66
            s5gyLCyO7ANuVRJx1NbgizcAblIgjtdf/u3WG7K+IiZhtELto/A7Fck9Ws6
            SQvzRvOE8uSirYbgmj6He4iO8NCyvaK0jIQRMMGQwsU1quGmFgHIXPLfnpn
            fajr1rVTAwtgV5LEZ4Iel+W1GC8ugMhyr4/p1MtcIM42EA8BzE6ZQqC7VPq
            PvEjZ2dbZkaBhPbiZGS3YeYBRDWm1p1OZtWamT3cEvqqPpnjL1XyW+oyVVk
            aZdklLQp2Btgt9qr21m42f4wTw+Xrp6rCKNb0CAwEAATANBgkqhkiG9w0BA
            QUFAAOCAQEAh8zGlfSlcI0o3rYDPBB07aXNswb4ECNIKG0CETTUxmXl9KUL
            +9gGlqCz5iWLOgWsnrcKcY0vXPG9J1r9AqBNTqNgHq2G03X09266X5CpOe1
            zFo+Owb1zxtp3PehFdfQJ610CDLEaS9V9Rqp17hCyybEpOGVwe8fnk+fbEL
            2Bo3UPGrpsHzUoaGpDftmWssZkhpBJKVMJyf/RuP2SmmaIzmnw9JiSlYhzo
            4tpzd5rFXhjRbg4zW9C+2qok+2+qDM1iJ684gPHMIY8aLWrdgQTxkumGmTq
            gawR+N5MDtdPTEQ0XfIBc2cJEUyMTY5MPvACWpkA6SdS4xSvdXK3IVfOWA=="]
            }    
    }

\[Editor: the jwk above was copy and pasted from the JWK example. Replace? ]

The certificate could be signed by the GS, allowing the GS to verify the signature using the GS public key, or the certificate could be signed by a private key the GS has bound to the Registered Client, allowing each instance of the Registered Client to have its own asymetric key pair.

A non-normative example of a JOSE header for a Dynamic Client including the public key generated by the Client that matches its its private key:

    {
        "alg":"ES256",
        "typ":"JOSE",
        "jwk":{
            "kty":"EC",
            "crv":"P-256",
            "x":"Kgl5DJSgLyV-G32osmLhFKxJ97FoMW0dZVEqDG-Cwo4",
            "y":"GsL4mOM4x2e6iON8BHvRDQ6AgXAPnw0m0SfdlREV7i4"
        }
    }

A non-normative example of a JOSE header for a JOSE access token for a Client accessing an RS that requires proof-of-possession:

    {
        "alg":"ES256",
        "typ":"JOSE",
        "jwk":{
            "x5u":"https://as.example/jwk/VBUEOIQA82" 
        }
    }

The "jwk" object in a JOSE access token {{JOSEAccessToken}} MUST be the GS jwk object the GS provided with the access handle. 

This decouples how the GS communicates the Client's public key to the RS from how the GS asserts the Client's public key. The RS can have a consistent mechanism assert the Client's public key across all Clients.

One advantage of this is the GS can create a certificate of a Dynamic Client's public key, and pass it by value or reference to the Client to present to the RS.

All JOSE headers MUST have:

+ the "alg" attribute.
+ the "typ" attribute set to "jose".
+ either a "kid" or "jwk" attribute.

\[Editor: should we use indicate the type of token (authorization, refresh, access) using "typ" or "cty"?]


**  Grant Token {#GrantToken}

A non-normative example of a grant token payload follows:

    {
        "iat"   :15790460234,
        "jti"   :"f6d72254-4f23-417f-b55e-14ad323b1dc1",
        "uri"   :"https://as.example/endpoint/example.grant",
        "verb"  :"GET"
    }

The payload of the grant token contains:

**as_uri** - the unique string identifier for the GS.

**iat** - the time the grant token was created as a NumericDate.

**jti** - a unique identifier for the grant token per {{RFC7519}} section 4.1.7.

**Grant URI** the Grant URI for the Grant.

**  Refresh Token {#RefreshToken}

A non-normative example of a refresh token payload follows:

    {
        "iat"   :15790460234,
        "jti"   :"473c9a02-966a-4f55-b904-bef5029d0bc7",
        "uri"   :"https://as.provider/endpoint/example.authn"
    }

The payload of the refresh token contains:

**as_uri** - the unique string identifier for the GS.

**iat** - the time the refresh token was created as a NumericDate.

**jti** - a unique identifier for the refresh token.

**Authorization URI** - the Authorization URI for the refreshing the access token.


**  JOSE Access Token {#JOSEAccessToken}

The "jwk" object in a JOSE access token header MUST be set to the "jwk" value the GS provided for the access handle. 

A non-normative example of a payload follows:

    {
        "iat"           :15790460234,
        "jti"           :"5ef47057-08f9-4763-be8d-162824d43dfb",
        "access token"  :"eyJhb958.access.token.9yf3szM"
    }

The payload of the JOSE access token contains:

**iat** - the time the JOSE access token was created as a NumericDate.

**jti** - a unique identifier for the JOSE access token.



\[Editor: should we include the called URI in the token?]


** HTTP Authorization Header {#JOSEHTTP}

HTTP Authorization JOSE Header {#JOSEHTTP}

The Client authenticates requests by setting the HTTP Authentication header to include the "JOSE" parameter, followed by one or more space characters, followed by the appropriate JOSE token. 

A non-normative example:

    Authorization: JOSE eyJhb.example.authorization.token.haDwskpFDBW

The authorization request token, refresh request token, and the JOSE access token are all passed in this manner.


**Authentication Server API**

| Request             |What is signed         | Passed in http
|:---                 |---                    |:---                
| Create Grant        | Grant JSON            | body
| Read Grant          | Grant Token           | header
| Update Grant        | Grant JSON            | body
| Delete Grant        | Grant Token           | header
| Refresh AuthZ       | Refresh Token         | header




**  Grant Request {#GrantRequest}

The Client creates a JSON document per {{CreateGrantSeq}}, signs it using JWS {{RFC7515}}, and sends the JWS token to the GS end point using HTTP POST, with a content-type of application/jose.

+ **Payload Encryption**

The GS may require the Grant Request to be encrypted. If so, the JWS token is encrypted per JWE {{RFC7516}} using the public key and algorithm specified by the GS.

**  Authorization Request 

The Client makes an HTTP GET call to the authorization uri, setting the HTTP Authorization header per --JOSE-- with the authorization request token.

A non-normative Authorization Request example:

    GET /authorization/ey7snHGs HTTP/2
    Host: as.example
    Authorization: JOSE eyJhb.example.authorization.token.haDwskpFDBW

**  Authentication Request {#AuthenticationRequest}

**  Update Grant Request {#UpdateGrantRequest}

**  Delete Grant Request  {#DeleteGrantRequest}

The Client MAY delete an outstanding request using the authorization token by making an HTTP DELETE call to the authorization uri, setting the HTTP Authorization header per --JOSE-- with the authorization request token. 

A non-normative deletion request example:

    DELETE /authorization/ey7snHGs HTTP/2
    Host: as.example
    Authorization: JOSE eyJhb.example.authorization.token.haDwskpFDBW

+ **Error Responses**

The GS MAY respond with one of the following errors defined in {{ErrorResponses}}:

    TBD



If the Client received a refresh handle and uri from the GS in the Interaction Response, and it wants a fresh access token or handle, it creates a refresh request token per xxx.  setting the HTTP Authorization header per --JOSE-- with the refresh request token. The GS will then respond with a refresh response.

+ **Access Response**



If a new refresh handle and/or refresh uri is returned, the Client MUST use the new refresh handle and/or refresh uri

\[Editor: are there other results relevant for {{RAR}}?]

+ **Error Responses**

The GS MAY respond with one of the following errors defined in {{ErrorResponses}}:

    TBD

** RS Access

**  Bearer Token {#Bearer}

If the access method in the Grant Response authorization object {{ResponseAuthorizationObject}} was "bearer", then the Client accesses the RS per Section 2.1 of {{RFC6750}}

A non-normative example of the HTTP request headers follows:

    GET /calendar HTTP/2
    Host: calendar.example
    Authorization: bearer eyJJ2D6.example.access.token.mZf9pTSpA

+ **Error Responses**

TBD

**  Proof-of-possession ----

If the access method in the Grant Response authorization object {{ResponseAuthorizationObject}} was "pop", then the Client creates a JOSE access token per {{JOSEAccessToken}} for each call to the RS, setting the HTTP Authorization header per --JOSE-- with the JOSE access token.

A non-normative example of the HTTP request headers follows:

    GET /calendar HTTP/2
    Host: calendar.example
    Authorization: JOSE eyJhbG.example.JOSE.access.token.kwwQb958

+ **Error Responses**

TBD

**  JOSE Body -

If the access method in the Grant Response authorization object {{ResponseAuthorizationObject}} was "pop_body", then the Client creates a JOSE access token per {{JOSEAccessToken}} for each call to the RS, setting the HTTP Authorization header per --JOSE-- with the JOSE access token.

The Client creates a JSON document per the RS requirements. The document MUST include the access handle. The CLient then signs the document using JWS [RFC7515], and sends the resulting compact notation JWS token to the RS end point using HTTP POST, with a content-type of application/jose. Note this is similar to the Grant Request  .

\[Editor: any isues here? Anything missing that MUST be in the payload? Would an HTTP Authorization header make sense?]






# Extensibility

This standard can be extended in a number of areas:

+ **Client Authentication Mechanisms**

An extension could define other mechanisms for the Client to authenticate and replace JOSE in {{ClientAuthN}} with Mutual TLS or HTTP Signing. Constrained environments could use CBOR {{RFC7049}} instead of JSON, and COSE {{RFC8152}} instead of JOSE, and CoAP {{RFC8323}} instead of HTTP/2.

+ **Grant**

An extension can define new objects in the Grant Request and Grant Response JSON. 

+ **Top Level**
Top level objects SHOULD only be defined to represent functionality other the existing top level objects and attributes.

+ **"client" Object**

Additional information about the Client that the GS would require related to an extension.

+ **"user" Object**

Additional information about the User that the GS would require related to an extension.

+ **"authorization" Object**

Additional types of authorizations in addition to OAuth 2.0 scopes and RAR.

+ **"claims" Object**

Additional types of identity claims in addition to OpenID Connect claims and Verified Credentials.

+ **Interaction types**

Additional types of interactions a Client can start with the User.

+ **Access Mechanisms**

Additional mechanisms for the Client to present access tokens to a resource.


+ **Continuous Authentication**

An extension could define a new handle for the Client to use to regularly provide continuous authentication signals and receive responses.

\[Editor: do we specify access token / handle introspection in this document, or leave that to an extension?]

\[Editor: do we specify access token / handle revocation in this document, or leave that to an extension?]

# Rational

1. **Why is there only one mechanism for the Client to authenticate with the GS? Why not support other mechanisms?**

    Having choices requires implementers to understand which choice is preferable for them. Having one default mechanism in the document for the Client to authenticate simplifies most implementations. Extensions can specify other mechanisms that are preferable in specific environments. 

1. **Why is the default Client authentication JOSE rather than MTLS?**

    MTLS cannot be used today by a Dynamic Client. MTLS requires the application to have access below what is typically the application layer, that is often not available on some platforms. JOSE is done at the application layer. Many GS deployments will be an application behind a proxy performing TLS, and there are risks in the proxy passing on the results of MTLS.

1. **Why is the default Client authentication JOSE rather than HTTP signing?**

    There is currently no widely deployed open standard for HTTP signing. Additionally, HTTP signing requires passing all the relevant parts of the HTTP request to downstream services within an GS that may need to independently verify the Client identity.

1. **What are the advantages of using JOSE for the Client to authenticate to the GS and a resource?**
    
    Both Registered Clients and Dynamic Clients can have a private key, eliminating the public Client issues in OAuth 2.0, as a Dynamic Client can create an ephemeral key pair. Using asymetric cryptography also allows each instance of a Registered Client to have its own private key if it can obtain a certificate binding its public key to the public key the GS has for the Client. Signed tokens can be passed to downstream components in a GS or RS to enable independent verification of the Client and its request. The GS Initiated Sequence {{GSInitiatedGrant}} requires a URL safe parameter, and JOSE is URL safe.

1. **Why does the GS not return parameters to the Client in the redirect url?**

    Passing parameters via a browser redirection is the source of many of the security risks in OAuth 2.0. It also presents a challenge for smart devices. In this protocol, the redirection from the Client to the GS is to enable the GS to interact with the User, and the redirection back to the Client is to hand back interaction control to the Client if the redirection was a full browser redirect. Unlike OAuth 2.0, the identity of the Client is independent of the URI the GS redirects to.

1. **Why is there not a UserInfo endpoint as there is with OpenID Connect?**

    In OpenID Connect, obtaining claims over the redirect or the Token Endpoint are problematic. The redirect is limited in size, and is not secure. The Token Endpoint is intended to return tokens, and is limited by the "application/x-www-form-urlencoded" format. A UserInfo endpoint returns "application/json", and can return rich claims, just as the authorization uri in this protocol.

    \[Editor: is there some other reason to have the UserInfo endpoint? What are industry best practices now? ]
    
1. **Why is there still a Client ID? Could we not use a fingerprint of the public key to identify the Client?**

    Some GS deployments do not allow calls from Registered Clients, and provide different functionality to different Clients. A permanent identifier for the Client is needed for the Client developer and the GS admin to ensure they are referring to the same Client. The Client ID was used in OAuth 2.0, and it served the same purpose. 

1. **Why have both claims and authorizations?**

    There are use cases for each that are independent: authenticating a user vs granting access to a resource. A request for an authorization returns an access token or handle, while a request for a claim returns the claim.

1. **Why specify HTTP/2 or later and TLS 1.3 or later for Client and GS communication in {{ClientAuthN}}?**

    Knowing the GS supports HTTP/2 enables a Client to set up a connection faster. HTTP/2 will be more efficient when Clients have large numbers of access tokens and are frequently refreshing them at the GS as there will be less network traffic. Mandating TLS 1.3 similarly improves the performance and security of Clients and GS when setting up a TLS connection.

1. **Why do some of the JSON objects only have one child, such as the identifiers object in the user object in the Grant Request?**

    It is difficult to forecast future use cases. Having more resolution may mean the difference between a simple extension, and a convoluted extension.

1. **Why is the "iss" included in the "oidc" identifier object? Would the "sub" not be enough for the GS to identify the User?**

    The GS may use another GS to authenticate Users. The "iss" and "sub" combination is required to uniquely identify the User for any GS. 

1. **Why complicate the sequence with authentication_first?**

    A common pattern is to use an GS to authenticate the User at the Client. The Client does not know a priori if the User is a new User, or a returning User. Asking a returning User to consent releasing identity claims and/or authorizations they have already provided is a poor User experience, as is sending the User back to the GS. The Client requesting identity first enables the Client to get a response from the GS while the GS is still interacting with the User, so that the Client can request any identity claims/or authorizations required or desired.

1. **Why is there a JOSE Body access **POPBody** method for the Client?** 

    There are numerous use cases where the RS wants non-repudiation and providence of API calls. For example, the UGS Service Supplier Framework for Authentication and Authorization {{UTM}}.


# Acknowledgments

This draft derives many of its concepts from Justin Richer's Transactional Authorization draft {{TxAuth}}. 

Additional thanks to Justin Richer for his strong critique of earlier drafts.

# IANA Considerations

\[ JOSE parameter for Authorization HTTP header ]

TBD

# Security Considerations

TBD

--- back

# Document History

## draft-hardt-xauth-protocol-00

- Initial version

## draft-hardt-xauth-protocol-01

- text clean up
- added OIDC4IA claims
- added "jws" method for accessing a resource.
- renamed Initiation Request -> Grant Request
- renamed Initiation Response -> Interaction Response
- renamed Completion Request -> Authorization Request
- renamed Completion Response -> Grant Request
- renamed completion handle -> authorization handle
- added Authentication Request, Authentication Response, authentication handle

## draft-hardt-xauth-protocol-02

- text clean up
- removed discovery from sequence diagram
- renamed
- GS Endpoint is identifier for GS. Decouple GS Endpoint from OIDC issuer.


# Comparison with OAuth 2.0 and OpenID Connect

**Changed Features**

The major changes between this protocol and OAuth 2.0 and OpenID Connect are:

+ The Client uses a private key to authenticate in this protocol instead of the client secret in OAuth 2.0 and OpenID Connect.

+ The Client initiates the protocol by making a signed request directly to the GS instead of redirecting the User to the GS.

+ The Client does not pass any parameters in redirecting the User to the GS, nor receive any parameters in the redirection back from the GS.

+ The refresh_token has been replaced with a AuthZ URI that both represents the access, and is the URI to call to refresh access.

+ The Client can request identity claims to be returned independent of the ID Token. There is no UserInfo endpoint to query claims as there is in OpenID Connect.

+ The GS URI is the token endpoint. CHECK!!!s

**Preserved Features** 

+ This protocol reuses the OAuth 2.0 scopes, Client IDs, and access tokens of OAuth 2.0. 

+ This protocol reuses the Client IDs, Claims and ID Token of OpenID Connect.

+ No change is required by the Client or the RS for existing bearer token protected APIs.

**New Features**

+ A Grant represents the user identity claims and RS access granted to the Client.

+ The Client can update, retrieve, and delete a Grant.

+ The GS can initiate a flow by creating a Grant and redirecting the User to the Client with the Grant URI.

+ The Client can discovery if an GS has a User with an identifier before the GS interacts with the User.

+ The Client can request the GS to first authenticate the User and return User identity claims, and then the Client can update Grant request based on the User identity.

+ Support for QR Code initiated interactions.

+ Each Client instance can have its own private / public key pair.

+ More Extensibility dimensions.

# Open Questions

1. 