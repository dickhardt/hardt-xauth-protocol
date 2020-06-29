---
docname: draft-hardt-xauth-protocol-06
title: The XAuth Protocol
date: 2020-03-22
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
  RFC3966:
  RFC5322:
  RFC4949:
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

Client software often desires resources or identity claims that are independent of the client. This protocol allows a user and/or resource owner to delegate resource authorization and/or release of identity claims to a server. Client software can then request access to resources and/or identity claims by calling the server. The server acquires consent and authorization from the user and/or resource owner if required, and then returns to the client software the authorization and identity claims that were approved. This protocol can be extended to support alternative authorizations, claims, interactions, and client authentication mechanisms.

--- middle

# Introduction

This protocol supports the widely deployed use cases supported by OAuth 2.0 {{RFC6749}} & {{RFC6750}}, and OpenID Connect {{OIDC}}, an extension of OAuth 2.0, as well as other extensions, and other use cases that are not supported, such as acquiring multiple access tokens at the same time, and updating the request during user interaction. This protocol also addresses many of the security issues in OAuth 2.0 by having parameters securely sent directly between parties, rather than via a browser redirection. 

The technology landscape has changed since OAuth 2.0 was initially drafted. More interactions happen on mobile devices than PCs. Modern browsers now directly support asymetric cryptographic functions. Standards have emerged for signing and encrypting tokens with rich payloads (JOSE) that are widely deployed.

Additional use cases are now being served with extensions to OAuth 2.0: OpenID Connect added support for authentication and releasing identity claims; {{RFC8252}} added support for native apps; {{RFC8628}} added support for smart devices; and support for {{browser based apps}} is being worked on. There are numerous efforts on adding proof-of-possession to resource access.

This protocol simplifies the overall architectural model, takes advantage of today's technology landscape, provides support for all the widely deployed use cases, and offers numerous extension points. 

While this protocol is not backwards compatible with OAuth 2.0, it strives to minimize the migration effort.

This protocol centers around a Grant, a representation of the collection of user identity claims and/or resource authorizations the Client is requesting, and the resulting identity claims and/or resource authorizations granted by the Grant Server.

\[Editor: suggestions on how to improve this are welcome!]

\[Editor: suggestions for other names than XAuth are welcome!]


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

- **Client** - requests a Grant from the GS to access one or more Resource Servers (RSs), and/or identity claims about the User. The Client can create, verify, retrieve, update, and delete a Grant. When a Grant is created, the Client receives from the GS the granted access token(s) for the RS(s), and identity claims about the User. The Client uses an access token to access the RS.  There are two types of Clients: Registered Clients and Dynamic Clients. All Clients have a key to authenticate with the Grant Server. 

- **Registered Client** - a Client that has registered with the GS and has a Client ID to identify itself, and can prove it possesses a key that is linked to the Client ID. The GS may have different policies for what different Registered Clients can request. A Registered Client MAY be interacting with a User.

- **Dynamic Client** - a Client that has not been registered with the GS, and each instance will generate it's own key pair so it can prove it is the same instance of the Client on subsequent requests, and to requests of a Resource Server that require proof-of-possession access. A single-page application with no active server component is an example of a Dynamic Client. A Dynamic Client MUST be interacting with a User.

- **Grant Server** (GS) - manages Grants for access to APIs at RSs and release of identity claims about the User. The GS may require explicit consent from the RO or User to provide these to the Client. A GS may support Registered Clients and/or Dynamic Clients. The GS is a combination of the Authorization Server (AS) in OAuth 2.0, and the OpenID Provider (OP) in OpenID Connect.

- **Resource Server** (RS) - has API resources that require an access token from the GS. Some, or all of the resources are owned by the Resource Owner.

- **Resource Owner** (RO) - owns resources at the RS, and has delegated RS access management to the GS. The RO may be the same entity as the User, or may be a different entity that the GS interacts with independently. GS and RO interactions are out of scope of this document.

## Reused Terms

- **access token** - an access token as defined in {{RFC6749}} Section 1.4.

- **Claim** - a Claim as defined in {{OIDC}} Section 5. Claims may be issued by the GS, or by other issuers. 

- **Client ID** - a GS unique identifier for a Registered Client as defined in {{RFC6749}} Section 2.2.

- **ID Token** - an ID Token as defined in {{OIDC}} Section 2.

- **NumericDate** - a NumericDate as defined in {{RFC7519}} Section 2.

- **authN** - short for authentication.

- **authZ** - short for authorization.

## New Terms

- **GS URI** - the endpoint at the GS the Client calls to create a Grant, and is the unique identifier for the GS.

- **Grant** - the user identity claims and/or RS authorizations the GS has granted to the Client.

- **Grant URI**  - the URI that represents the Grant. The Grant URI MUST start with the GS URI.

- **Authorization** - the access granted by the RO to the Client. Contains an access token.

- **Authorization URI** (AZ URI) - the URI that represents the Authorization the Client was granted by the RO. The AZ URI MUST start with the GS URI. The AZ URI is used to read, update, and delete an access token.

- **Redirect Interaction** - characterized by the GS returning the User back to the Client that started the interaction.

- **Indirect Interaction** - characterized by the GS not being able to return the User back to the Client that started the interaction. 

- **Redirect URI** - a URI at the GS that the Client will redirect the User to in a Redirect Interaction. This URI is unique is unique to an outstanding Create Grant request.

- **Completion URI** - the URI at the Client that the GS will redirect the User back to in a Redirect Interaction. If the Client has not set the interaction.verify flag, this URI is unique to the Create Grant request made by the Client.

- **Information URI** - the URI the GS will redirect the User to after an Indirect Interaction. 

- **Short URI** - a URI at the GS that is used in Indirect Interactions. The URI may be presented to the User as a scannable code, or loaded in a system browser by the Client. The URI has a maximum length of TBD bytes, and is unique to an outstanding Create Grant request. 

- **Code URI** - a URI at the GS presented to the User by the Client for the User to enter the User Code in an Indirect Interaction.

- **User Code** - a string generated by the GS that is is unique to an outstanding Create Grant request in an Indirect Interaction.  

## Notational Conventions

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

# Sequences

Before any sequence, the Client needs to be manually or programmatically configured for the GS. See GS Options {{GSoptions}} for details on acquiring GS metadata.

\[Editor: a plethora of sequences are included to illustrate all the different use cases that are supported. Many sequences are similar, and show a slightly different sequence that can support different use cases. These could potentially be moved to a use case document in the future.]

## Create and Verify Grant {#CreateVerifyGrantSeq}

A Dynamic Client wants a Grant from the User using a Redirect Interaction:

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Create Grant ----------->|       |
    |        |                                  |       |
    |        |<--- Interaction Response ---(2)--|       |         +------+
    |        |                                  |       |         | User |
    |        |--(3)--- Interaction Transfer --- | - - - | ------->|      |
    |        |                                  |       |         |      |
    |        |                                  |       |<--(4)-->|      |
    |        |                                  |       |  authN  |      |
    |        |                                  |       |<--(5)-->|      |
    |        |                                  |       |  authZ  |      |
    |        |<--- Interaction Transfer ---(6)- | - - - | --------|      |
    |        |                                  |       |         |      |
    |        |--(7)--- Verify Grant ----------->|       |         +------+
    |        |                                  |       |
    |        |<--------- Grant Response ---(8)--|       |
    |        |                                  |       |
    +--------+                                  +-------+
 
1. **Create Grant** The Client creates a Request JSON document {{RequestJSON}} and makes a Create Grant request ({{CreateGrant}}) by sending the JSON with an HTTP POST to the GS URI.

2. **Interaction Response**  The GS determines that interaction with the User is required and sends an Interaction Response ({{InteractionResponse}}) containing the Grant URI and an interaction object.

3. **Interaction Transfer** The Client redirects the User to the Redirect URI at the GS.

4. **User Authentication** The GS authenticates the User.

5. **User Authorization** If required, the GS interacts with the User to determine which identity claims and/or authorizations in the Grant Request are to be granted.

6. **Interaction Transfer** The GS redirects the User to the Completion URI at the Client, passing an Interaction Nonce. 

7. **Read Grant** The Client creates a JSON document containing a verification object {{VerificationObject}} and does a Verify Grant {{VerifyGrant}} request by HTTP PATCH with the document to the Grant URI.

8. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}).


## Create and Read Grant - Redirect {#CreateReadGrantSeq}

A Registered Client wants a Grant from the User using a Redirect Interaction:

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Create Grant ----------->|       |
    |        |                                  |       |
    |        |<--- Interaction Response ---(2)--|       |
    |        |                                  |       |
    |        |--(3)--- Read Grant ------------->|       |         +------+
    |        |                                  |       |         | User |
    |        |--(4)--- Interaction Transfer --- | - - - | ------->|      |
    |        |                                  |       |         |      |
    |        |                                  |       |<--(5)-->|      |
    |        |                                  |       |  authN  |      |
    |        |                                  |       |<--(6)-->|      |
    |        |                                  |       |  authZ  |      |
    |        |<--------- Grant Response ---(7)--|       |         |      |
    |        |                                  |       |         |      |
    |        |<--- Interaction Transfer ---(8)- | - - - | --------|      |
    |        |                                  |       |         |      |
    +--------+                                  +-------+         +------+
 
1. **Create Grant** The Client makes a Create Grant request ({{CreateGrant}}) to the GS URI.

2. **Interaction Response**  The GS determines that interaction with the User is required and sends an Interaction Response ({{InteractionResponse}}) containing the Grant URI and an interaction object.

3. **Read Grant** The Client does an HTTP GET of the Grant URI ({{ReadGrant}}).

4. **Interaction Transfer** The Client transfers User interaction to the GS.

5. **User Authentication** The GS authenticates the User.

6. **User Authorization** If required, the GS interacts with the User to determine which identity claims and/or authorizations in the Grant Request are to be granted.

7. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}).

8. **Interaction Transfer** The GS redirects the User to the Completion URI of the Client. The Client verifies it is the same User that it transferred to the GS.


## Create and Read Grant - Indirect {#CreateReadGrantIndirectSeq}

A Registered Client wants a Grant from the User using an Indirect Interaction:

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Create Grant ----------->|       |
    |        |                                  |       |
    |        |<--- Interaction Response ---(2)--|       |
    |        |                                  |       |
    |        |--(3)--- Read Grant ------------->|       |         +------+
    |        |                                  |       |         | User |
    |        |--(4)--- Interaction Transfer --- | - - - | ------->|      |
    |        |                                  |       |         |      |
    |        |                                  |       |<--(5)-->|      |
    |        |                                  |       |  authN  |      |
    |        |                                  |       |<--(6)-->|      |
    |        |                                  |       |  authZ  |      |
    |        |<--------- Grant Response ---(7)--|       |         |      |
    +--------+                                  |       |         |      |
                                                |       |         |      |
    +--------+                                  |       |         |      |
    |  Info  |<--- Interaction Transfer ---(8)- | - - - | --------|      |
    | Server |                                  |       |         |      |
    +--------+                                  +-------+         +------+
 
The sequence is the same except:

- In step (4) the User either scans a bar code or uses a separate device to navigate to the Code URI and enters the User Code.

- In step (8) the GS redirects the User to the Information URI provided by the Client.



## Reciprocal Grant

Party A and Party B are both a Client and a GS, and each Client would like a Grant for the other GS. The sequence starts off the same as in {{CreateReadGrantSeq}}, but Party B makes a Create Grant Request before sending a Grant Response:

                    Party A                                    Party B
                   +--------+                                 +--------+
                   | Client |                                 |   GS   |
                   ~ ~ ~ ~ ~ ~     Same as steps 1 - 6 of    ~ ~ ~ ~ ~ ~
    +------+       |        |   Create and Read Grant above   |        |
    | User |       |        |                                 |        |
    |      |       |   GS   |<--------- Create Grant ---(1)---| Client |
    |      |       |        |                                 |        |
    |      |       |        |<------- Grant Response ---(2)---|        |
    |      |       |        |                                 |        |
    |      |<----- | - - -  | -- Interaction Transfer --(3)---|        |
    |      |       |        |                                 |        |
    |      |<-(4)->|        |                                 |        |
    |      | AuthZ |        |                                 |        |
    +------+       |   GS   |--(5)--- Grant Response -------->| Client |
                   |        |                                 |        |
                   +--------+                                 +--------+


1. **Create Grant** Party B creates a Grant Request ({{CreateGrant}}) with user.reciprocal set to the Party B Grant URI that will be in the step (2) Grant Response, and sends it with an HTTP POST to the Party A GS URI. This enables Party A to link the reciprocal Grants.

2. **Grant Response** Party B responds to Party A's Create Grant Request with a Grant Response that includes the Party B Grant URI.

3. **Interaction Transfer** Party B redirects the User to the Completion URI at Party A.

4. **User Authorization** If required, Party A interacts with the User to determine which identity claims and/or authorizations in Party B's Create Grant Request are to be granted.

5. **Grant Response** Party A responds with a Grant Response ({{GrantResponse}}).


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

## Create and Update {#CreateAndUpdate}

The Client requests an identity claim to determine who the User is. Once the Client learns who the User is, and the Client updates the Grant for additional identity claims which the GS prompts the User for and returns to the Client. Once those are received, the Client updates the Grant with the remaining identity claims required.

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Create Grant ----------->|       |
    |        |      interaction.keep:true       |       |
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
    |        |      interaction.keep:true       |       |<--(9)-->|      |
    |        |                                  |       |  authZ  |      |
    |        |<--------- Grant Response --(10)--|       |         |      |
    |  (11)  |                                  |       |         |      |
    |  eval  |--(12)-- Update Grant ----------->|       |         |      |
    |        |  interaction.keep:false          |       |<--(13)->|      |
    |        |                                  |       |  authZ  |      |
    |        |                                  |       |         |      |
    |        |<--- Interaction Transfer --(14)- | - - - | --------|      |
    |        |                                  |       |         |      |
    |        |<--------- Grant Response --(15)--|       |         +------+
    |        |                                  |       |
    +--------+                                  +-------+

1. **Create Grant** The Client creates a Grant Request ({{CreateGrant}}) including an identity claim and interaction.keep:true, and sends it with an HTTP POST to the GS GS URI.

2. **Interaction Response**  The GS sends an Interaction Response ({{InteractionResponse}}) containing the Grant URI, an interaction object, and interaction.keep:true.

3. **Read Grant** The Client does an HTTP GET of the Grant URI ({{ReadGrant}}).

4. **Interaction Transfer** The Client transfers User interaction to the GS.

5. **User Authentication** The GS authenticates the User.

6. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}) including the identity claim from User authentication and interaction.keep:true.

7. **Grant Evaluation** The Client queries its User database and does not find a User record matching the identity claim. 

8. **Update Grant** The Client creates an Update Grant Request ({{UpdateGrant}}) including the initial identity claims required and interaction.keep:true, and sends it with an HTTP PUT to the Grant URI.

9. **User AuthN** The GS interacts with the User to determine which identity claims in the Update Grant Request are to be granted.

10. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}) including the identity claims released by the User and interaction.keep:true.

11. **Grant Evaluation** The Client evaluates the identity claims in the Grant Response and determines the remaining User identity claim required. 

12. **Update Grant** The Client creates an Update Grant Request ({{UpdateGrant}}) including the remaining required identity claims and interaction.keep:false, and sends it with an HTTP PUT to the Grant URI.

13. **User AuthZ** The GS interacts with the User to determine which identity claims in the Update Grant Request are to be granted.

14. **Interaction Transfer** The GS transfers User interaction to the Client.

15. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}) including the identity claims released by the User.


## Create and Delete

The Client requests an identity claim to determine who the User is. Once the Client learns who the User is, and the Client knows it already has all the identity claims and authorizations needed for the User, the Client deletes the Grant which prompts the GS to transfer the interaction back to the Client. (If the Client did not already have what was needed, the Client would follow the Create and Update sequence {{CreateAndUpdate}} )

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Create Grant ----------->|       |
    |        |      interaction.keep:true       |       |
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

1. **Create Grant** The Client creates a Grant Request ({{CreateGrant}}) including an identity claim and interaction.keep:true, and sends it with an HTTP POST to the GS GS URI.

2. **Interaction Response**  The GS sends an Interaction Response ({{InteractionResponse}}) containing the Grant URI, an interaction object, and interaction.keep:true.

3. **Read Grant** The Client does an HTTP GET of the Grant URI ({{ReadGrant}}).

4. **Interaction Transfer** The Client transfers User interaction to the GS.

5. **User Authentication** The GS authenticates the User.

6. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}) including the identity claim from User authentication and interaction.keep:true.

7. **Grant Evaluation** The Client queries its User database and finds the User record matching the identity claim, and that no additional claims or authorizations are required. 

8. **Delete Grant** The Client no longer needs the Grant and decides to Delete Grant ({{DeleteGrant}}) by sending an HTTP DELETE to the Grant URI. If the GS responds with success the Grant no longer exists.

## Create, Discover, and Delete

The Client wants to discover if the GS has a User with a given identifier. If not, it will abort the request and not transfer interaction to the GS.

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Create Grant ----------->|       |
    |        |      user.exists:true            |       |
    |        |                                  |       |
    |        |<--- Interaction Response ---(2)--|       |
    |        |         user.exists:false        |       |
    |        |                                  |       |
    |        |--(3)--- Delete Grant ----------->|       |
    |        |<------- Delete Response ---------|       |
    |        |                                  |       |
    +--------+                                  +-------+

1. **Create Grant** The Client creates a Grant Request ({{CreateGrant}}) including an identity claim request, a User identifier, and user.exists:true. The Client sends it with an HTTP POST to the GS GS URI.

2. **Interaction Response**  The GS sends an Interaction Response ({{InteractionResponse}}) containing the Grant URI, an interaction object, and user.exists:false.

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
    |        |                                  |       |  AuthZ  |      |
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

The Client wants to re-acquire the identity claims and authorizations in the Grant. No User or RO interaction is required as no new consent or authorization is required.

    +--------+                                  +-------+
    | Client |                                  |  GS   |
    |        |--(1)--- Read Grant ------------->|       |
    |        |                                  |       |
    |        |<--------- Grant Response --(2)---|       |
    |        |                                  |       |
    +--------+                                  +-------+

1. **Read Grant** The Client does an HTTP GET of the Grant URI ({{ReadGrant}}).

2. **Grant Response** The GS responds with a Grant Response ({{GrantResponse}}) containing updated identity claims and authorizations.

## Resource Server Access

The Client received an AZ URI from the GS. The Client acquires an access token, calls the RS, and later the access token expires. The Client then gets a fresh access token.


    +--------+                                           +-------+
    | Client |                                           |  GS   |
    |        |--(1)--- Read AuthZ ---------------------->|       |
    |        |<------- AuthZ Response -------------------|       |
    |        |                                           |       |
    |        |                             +----------+  |       | 
    |        |                             | Resource |  |       | 
    |        |--(2)--- Access Resource --->|  Server  |  |       | 
    |        |<------- Resource Response --|   (RS)   |  |       | 
    |        |                             |          |  |       | 
    |        |--(3)--- Access Resource --->|          |  |       | 
    |        |<------- Error Response -----|          |  |       |
    |        |                             |          |  |       | 
    |        |                             +----------+  |       |
    |        |                                           |       |
    |        |--(4)--- Read AuthZ ---------------------->|       |
    |        |<------- AuthZ Response -------------------|       |
    |        |                                           |       |
    +--------+                                           +-------+

1. **Read AuthZ** The Client makes a Read AuthZ ({{ReadAuthZ}}) with an HTTP GET to the AZ URI and receives an Response JSON "authorization" object ({{ResponseAuthorizationObject}}) with a fresh access token.

2. **Resource Request** The Client accesses the RS with the access token per {{RSAccess}} and receives a response from the RS.

3. **Resource Request** The Client attempts to access the RS, but receives an error indicating the access token has expired. 

4. **Read AuthZ** The Client makes another Read AuthZ ({{ReadAuthZ}}) with an HTTP GET to the AZ URI and receives an Response JSON "authorization" object ({{ResponseAuthorizationObject}}) with a fresh access token.


## GS API Table

| request            | http verb | uri          | response     
|:---                |---        |:---          |:--- 
| Create Grant       | POST      | GS URI       | interaction, wait, or grant 
| Verify Grant       | PATCH     | Grant URI    | grant 
| Read Grant         | GET       | Grant URI    | wait, or grant 
| Update Grant       | PUT       | Grant URI    | interaction, wait, or grant 
| Delete Grant       | DELETE    | Grant URI    | success 
| Read AuthZ         | GET       | AZ URI       | authorization 
| Update AuthZ       | PUT       | AZ URI       | authorization 
| Delete AuthZ       | DELETE    | AZ URI       | success 
| GS Options         | OPTIONS   | GS URI       | metadata 
| Grant Options      | OPTIONS   | Grant URI    | metadata 
| AuthZ Options      | OPTIONS   | AZ URI       | metadata  


\[ Editor: is there value in an API for listing a Client's Grants? eg:]

    List Grants     GET     GS URI    JSON array of Grant URIs


# Grant and AuthZ Life Cycle

\[Editor: straw man for life cycles.]


**Grant life Cycle**

The Client MAY create, read, update, and delete Grants. A Grant persists until it has expired, is deleted, or another Grant is created for the same GS, Client, and User tuple.

At any point in time, there can only be one Grant for the GS, Client, and User tuple. When a Client creates a Grant at the same GS for the same User, the GS MUST invalidate a previous Grant for the Client at that GS for that User.

**Authorization Life Cycle**

An Authorization are represented by an AZ URI and are MAY be included in a Grant Response "authorization" Object ({{ResponseAuthorizationObject}}) or as a member of the Grant Response "authorizations" list. If a Client receives an Authorization, the Client MUST be able to do a Read AuthZ request {{ReadAuthZ}}, and MAY be able to update {{UpdateAuthZ}} and delete {{DeleteAuthZ}} depending on GS policy. 

An Authorization will persist independent of the Grant, and persist until invalidated by the GS per GS policy, or deleted by the Client.  



# GS APIs

**Client Authentication**

All APIs except for GS Options require the Client to authenticate. 

This document defines the JOSE Authentication mechanism in {{JOSEauthN}}. Other mechanisms include \[TBD].


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

The GS MUST respond with one of Grant Response {{GrantResponse}}, Interaction Response {{InteractionResponse}}, Wait Response {{WaitResponse}}, or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

Following is a non-normative example where the Client is requesting identity claims about the User and read access to the User's contacts:

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
            "redirect": {
                "completion_uri"    : "https://web.example/return"
            },
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


Following is a non-normative example where the Client is requesting the GS to keep the interaction with the User after returning the ID Token so the Client can update the Grant, and is also asking if the user exists:

    Example 2

    { 
        "iat"       : 15790460234,
        "uri"       : "https://as.example/endpoint",
        "nonce"     : "5c9360a5-9065-4f7b-a330-5713909e06c6",
        "client": {
            "id"        : "di3872h34dkJW"
        },
        "interaction": {
            "indirect": {
TBD
            },
            "user_code": {
TBD
            }
        },
        "user": {
            "identifiers": {
                "email" : "jane.doe@example.com"
            },
            "exists"    : true
        },
        "claims"    : { "oidc": { "id_token" : {} } }
    }


## Verify Grant {#VerifyGrant}

The Client verifies a Grant by doing an HTTP PATCH of a JSON document to the corresponding Grant URI.

The JSON document MUST contain verification.nonce per {{VerificationObject}}. Following is a non-normative example:

    {
        "verification": { "nonce":"55e8a90f-a563-426d-8c35-d6d8ed54afeb" }
    }

The GS MUST respond with one of Grant Response {{GrantResponse}} or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

## Read Grant {#ReadGrant}

The Client reads a Grant by doing an HTTP GET of the corresponding Grant URI.

The GS MUST respond with one of Grant Response {{GrantResponse}}, Wait Response {{WaitResponse}}, or one of the following errors:

+ TBD

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

The GS MUST respond with one of Grant Response {{GrantResponse}}, Interaction Response {{InteractionResponse}}, Wait Response {{WaitResponse}}, or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

Following is a non-normative example where the Client made an interaction.keep:true request, and now wants to update the request with additional claims:

    Example 3

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

## Request JSON {#RequestJSON}


\[Editor: do we want to reuse the JWT claims "iat", "jti", etc.? ]

+ **iat** - the time of the request as a NumericDate.

+ **nonce** - a unique identifier for this request. Note the Grant Response MUST contain a matching nonce attribute value.

+ **uri** - the GS URI if in a Create Grant {{CreateGrant}}, or the Grant URI if in an Update Grant {{UpdateGrant}}.


### "client" Object
The client object MUST contain either the id attribute for Registered Clients, or the display object for Dynamic Clients.

+ **id** - the Client ID the GS has for the Registered Client.

+ **display** - the display object contains the following attributes:

    + **name** - a string that represents the Dynamic Client

    + **uri** - a URI representing the Dynamic Client 


The name and uri will be displayed by the GS when prompting for authorization.

\[Editor: a max length for the name and URI so a GS can reserve appropriate space?]

### "interaction" Object
The interaction object contains the type of interaction the Client will provide the User. Other attributes 

+ **keep** - a JSON boolean. If set to the JSON value true, the GS will not transfer the User interaction back to the Client after processing the Grant request. The JSON value false is equivalent to the attribute not being present, and the GS will transfer the User interaction back to the Client after processing the request. This attribute is OPTIONAL


+ **type** - contains one of the following values: "redirect" or "indirect". Details in {{InteractionType}}. This attribute is REQUIRED.

\[Editor: do we want this to be an array of types the Client can support? This would only be the case if the GS is not able to support all types and negotiation is required. Is that required?]

+ **completion_uri** - this attribute is REQUIRED if the type is "redirect". It is the URI that the Client requests the GS to redirect the User to after the GS has completed interacting with the User. If the Client manages session state in URIs, then the redirect_uri SHOULD contain that state.

+ **information_uri** - this attribute is OPTIONAL and is ignored unless the type is "indirect". This is the URI the Client would like the GS to redirect the User to after the interaction with the User is complete. 

+ **ui_locales** - End-User's preferred languages and scripts for the user interface, represented as a space-separated list of {{RFC5646}} language tag values, ordered by preference. This attribute is OPTIONAL.

+ **verify** - a boolean value. If set to the JSON value true, the GS will return a nonce value with the Completion URI.






### "user" Object {#RequestUserObject}

+ **exists** - if present, MUST contain the JSON true value. Indicates the Client requests the GS to return a user.exists value in an Interaction Response {{InteractionResponse}}. This attribute is OPTIONAL, and MAY be ignored by the GS.

+ **identifiers** - REQUIRED if the exists attribute is present. The values MAY be used by the GS to improve the User experience. Contains one or more of the following identifiers for the User:

    + **phone_number** - contains a phone number per Section 5 of {{RFC3966}}.

    + **email** - contains an email address per {{RFC5322}}.

    + **oidc** - is an object containing both the "iss" and "sub" attributes from an OpenID Connect ID Token {{OIDC}} Section 2.

+ **claims** - an optional object containing one or more assertions the Client has about the User.

    + **oidc_id_token** - an OpenID Connect ID Token per {{OIDC}} Section 2.

+ **reciprocal** - indicates this Grant Request or Update is the reciprocal of another Grant. Contains the Grant URI of the reciprocal Grant. 

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


### "verification" Object {#VerificationObject}

The verification Object is used with the Verify Grant {{VerifyGrant}}.

+ **nonce** the Interaction Nonce received from the GS via the Completion URI. This attribute MUST only be used in the Verify Grant {{VerifyGrant}}.


\[Editor: parameters for the Client to request it wants the Grant Response signed and/or encrypted?]


## Read Authorization {#ReadAuthZ}

The Client acquires an Authorization by doing an HTTP GET to the corresponding AZ URI.

The GS MUST respond with a Authorization JSON document {{AuthorizationJSON}}, or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

## Update Authorization {#UpdateAuthZ}

The Client updates an Authorization by doing an HTTP PUT to the corresponding AZ URI of the following JSON. All of the following MUST be included.

+ **iat** - the time of the response as a NumericDate.

+ **uri** - the AZ URI.

+ **authorization** - the new authorization requested per the Request JSON "authorization" object {{AuthorizationObject}}.

The GS MUST respond with a Authorization JSON document {{AuthorizationJSON}}, or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

## Delete Authorization {#DeleteAuthZ}

The Client deletes an Authorization by doing an HTTP DELETE to the corresponding AZ URI.

The GS MUST respond with OK 200, or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.


## GS Options {#GSoptions}

The Client can get the metadata for the GS by doing an HTTP OPTIONS of the corresponding GS URI. This is the only API where the GS MAY respond to an unauthenticated request.

The GS MUST respond with the the following JSON document:

\[Editor: this section is a work in progress]


+ **uri** - the GS URI.

+ **client_authentication** - an array of the Client Authentication mechanisms supported by the GS

+ **interactions** - an array of the interaction types supported by the GS.

+ **authorization** - an object containing the authorizations the Client may request from the GS, if any.

    + Details TBD

+ **claims** - an object containing the identity claims the Client may request from the GS, if any, and what public keys the claims will be signed with.

    + Details TBD

+ **algorithms** - a list of the cryptographic algorithms supported by the GS. 

+ **features** - an object containing feature support

    + **user_exists** - boolean indicating if user.exists is supported.

    + **authorizations** - boolean indicating if a request for multiple authorizations is supported.


\[Editor: keys used by Client to encrypt requests, or verify signed responses?]

\[Editor: namespace metadata for extensions?]

or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

##  Grant Options {#GrantOptions}


The Client can get the metadata for the Grant by doing an HTTP OPTIONS of the corresponding  Grant URI.

The GS MUST respond with the the following JSON document:

+ **verbs** - an array of the HTTP verbs supported at the GS URI.


or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.

## AuthZ Options {#AuthZOptions}


The Client can get the metadata for the AuthZ by doing an HTTP OPTIONS of the corresponding AZ URI.

The GS MUST respond with the the following JSON document:

+ **verbs** - an array of the HTTP verbs supported at the GS URI.


or one of the following errors:

+ TBD

from Error Responses {{ErrorResponses}}.


## Request Verification

On receipt of a request, the GS MUST verify the following:

+ TBD

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

and MAY include the following from the Response JSON {{ResponseJSON}}

+ authorization or authorizations
+ claims
+ expires_in

Example non-normative Grant Response JSON document for Example 1 in {{CreateGrant}}:

    { 
        "iat"           : 15790460234,
        "nonce"         : "f6a60810-3d07-41ac-81e7-b958c0dd21e4",
        "uri"           : "https://as.example/endpoint/grant/example1",
        "expires_in"    : 300
        "authorization": {
            "type"          : "oauth_scope",
            "scope"         : "read_contacts",
            "expires_in"    : 3600,
            "mechanism"     : "bearer",
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

Example non-normative Grant Response JSON document for Example 2 in {{CreateGrant}}:

    {
        "iat"   : 15790460234,
        "nonce" : "5c9360a5-9065-4f7b-a330-5713909e06c6",
        "uri"   : "https://as.example/endpoint/grant/example2",
        "authorization": {
            "uri"   : "https://as.example/endpoint/authz/example2"
        }
    }


## Interaction Response {#InteractionResponse}

The Interaction Response MUST include the following from the Response JSON {{ResponseJSON}}

+ iat
+ nonce
+ uri
+ interaction

and MAY include the following from the Response JSON {{ResponseJSON}}

+ user
+ wait

A non-normative example of an Interaction Response follows:

    {
        "iat"       : 15790460234,
        "nonce"     : "0d1998d8-fbfa-4879-b942-85a88bff1f3b",
        "uri"       : "https://as.example/endpoint/grant/example4",
        "interaction" : {
            "type"             : "redirect",
            "redirect_uri"     : "https://as.example/i/example4"
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

A non-normative example of Wait Response follows:

    {
        "iat"       : 15790460234,
        "nonce"     : "0d1998d8-fbfa-4879-b942-85a88bff1f3b",
        "uri"       : "https://as.example/endpoint/grant/example5",
        "wait"      : 300
    }

## Response JSON {#ResponseJSON}

Details of the JSON document: 

+ **iat** - the time of the response as a NumericDate.

+ **nonce** - the nonce that was included in the Request JSON {{RequestJSON}}.

+ **uri** - the Grant URI.

+ **wait** - a numeric value representing the number of seconds the Client should want before making a Read Grant request to the Grant URI.

+ **expires_in** - a numeric value specifying how many seconds until the Grant expires. This attribute is OPTIONAL.

### "interaction" Object {#interactionObject}

If the GS wants the Client to start the interaction, the GS MUST return the interaction mechanism provided by the Client in the Grant Request, and include the required attributes in the interaction object: 

+ **type** - this MUST match the type provided by the Client in the Grant Request client.interaction object.

+ **authorization_uri** - the URI to redirect the user to or load in the popup. Must be included if type is "redirect"

+ **display_uri** - the URI to be displayed to the User for them to navigate to and enter the code. Must be included if type is "indirect"


+ **user_code** - a text string of the code to display to the User. Must be included if type is "indirect".

+ **short_uri** - the URI to show as scannable code. MUST be included if type is "indirect"

\[Editor: do we specify a maximum length for the display_uri and code so that a device knows the maximum it needs to support? A smart device may have limited screen real estate.]

The authorization_uri, qr_uri, and user_code MUST be unique and only match the associated Grant URI.

TBD: entropy and other security considerations for the authorization_uri, qr_uri, and the user_code.

See Interaction Types {{InteractionType}} for details.

### "user" Object

+ **exists** - a boolean value indicating if the GS has a user with one or more of the provided identifiers in the Request user.identifiers object {{RequestUserObject}}


### "authorization" Object {#ResponseAuthorizationObject}

The Response JSON authorization object is a subset of the Authorization JSON {{AuthorizationJSON}}. It contains only the AZ URI if the Client is able to read, update and/or delete the Authorization. Alternatively, it contains the Authorization JSON excluding the AZ URI. See Grant Response {{GrantResponse}} for non-normative examples.

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


## Authorization JSON {#AuthorizationJSON}

The Authorization JSON is a response to a Read AuthZ request by the Client {{ReadAuthZ}}. A subset of the Authorization JSON is included in the "authorization" object {{AuthorizationObject}} and "authorizations" list members {{ResponseAuthorizationsObject}}.

+ **type** - the type of claim request: "oauth_scope" or "oauth_rich". See the "type" object in {{AuthorizationObject}} for details. 

+ **scope** - the scopes the Client was granted authorization for. This will be all, or a subset, of what was requested. This attribute is OPTIONAL.

+ **authorization_details** - the authorization details granted per {{RAR}}. Included if type is "oauth_rich".

+ **mechanism** - one of the access mechanisms: "bearer", "jose", or "jose+body". See {{RSAccess}} for details.

+ **token** - the access token for accessing an RS.  This attribute is REQUIRED.

+ **expires_in** - a numeric value specifying how many seconds until the access token expires. This attribute is OPTIONAL.

+ **certificate** - MUST be included if the mechanism is "jose" or "jose+body". Contains the jwk header values for the Client to include in the JWS header when calling the RS using the "jose" or "jose+body" mechanisms. See {{JWSHeader}}.

+ **uri** - the AZ URI. Used to get, update, and delete the authorization. This will be the same URI that was used in a Read Authorization or Update Authorization request. This attribute is REQUIRED unless it is in a Response JSON,

\[Editor: any value in an expiry for the Authorization?]

The following is a non-normative example of an Authorization JSON document:

    {
        "type"          : "oauth_scope",
        "scope"         : "read_calendar write_calendar",
        "mechanism"     : "jose",
        "token"         : "eyJJ2D6.example.access.token.mZf9p"
        "expires_in"    : 3600,
        "certificate": {
            "x5u"   : "https://as.example/cert/example2" 
        },
        "uri"       : "https://as.example/endpoint/authz/example2"
    }

### Signing and Encryption


\[Editor: TBD - how response is signed and/or encrypted by the GS. Is there a generalized description, or is it mechanism specific?]

## Response Verification

On receipt of a response, the Client MUST verify the following:

+ TBD


# Interactions {#InteractionType}

There are two types of interactions that a Client can initiate with a GS: redirect and indirect. Extensions may define additional interaction types.

## Redirect Interaction

A Redirect Interaction is characterized by the GS returning the User back to the Client that started the interaction. After a redirect back from the GS, the Client may be able to securely verify the returning User is the same as the User the Client redirected to the GS by verifying a unique Completion URI is associated with a browser cookie set prior to the redirection. Clients that are not able to securely verify the returning User, or do not want to, verify the User by making a Verify Grant call to the GS, passing the Interaction Nonce. The Client signals to the GS that it requires an Interaction Nonce by setting interaction.verify to true. Following is the Redirect Interaction sequence:

1. If not interaction.verify, the Client creates a unique Completion URI.
1. The Client creates a Grant Request setting interaction.type to "redirect" and interaction.completion_uri to the Completion URI, and makes a Create Grant request. 
1. The GS creates a Grant with a unique Grant URI and Authorization URI and binds them to the Completion URI.
1. The GS creates an Interaction Response setting interaction.type to "redirect" and interaction.authorization_uri to the Authorization URI and returns it to the Client.
1. If not interaction.verify, the Client creates and sets a a unique completion browser cookie and binds it to the completion URI. The cookie MUST not be able to be used to derive the Completion URI.
1. The Client redirects the User's browser to the Authorization URI using any available browser redirect mechanism.
1. The GS locates the Grant bound to the Authorization URI.
1. The GS interacts with the User.
1. If interaction.verify, the GS creates an Interaction Nonce, binds it to the Grant, and appends it to the Completion URI as the "nonce" query parameter.
1. The GS redirects the User's browser to the Completion URI using any available browser redirect mechanism. 
1. If not interaction.verify, the Client confirms the completion browser cookie is bound to the Completion URI.
1. If interaction.verify, the Client makes a Verify Grant call with the Interaction Nonce, and the Grant.

A GS MUST support the Redirect Interaction type.


## Indirect Interaction

An Indirect Interaction is characterized by the GS not being able to return the User back to the Client that started the interaction. There are two mechanisms for a User to identify the Client's Create Grant request at the GS: Short URI or User Code.

1. Generation
    1. The GS generates a Short URI and User Code unique to the Grant.
    1. The GS sends the Short URI, Code URI, and User Code to the Client.
1. Display
    1. If possible, the Client MAY display the Short URI to the User as a scannable code such as a {{QR Code}}. The User MAY then scan the image that will open the Short URI on the User's scanning device.
    1. The Client MAY optionally launch a system browser to open the Short URI.
    1. The Client MUST display the User Code and instructions to enter it at the Code URI. The User MAY navigate a browser on a separate device to the Code URI.

If the User arrived at the GS via the Short URI, the GS will use the Short URI to identify the Create Grant request, and then authenticate the User.

If the User arrived at the GS via the Code URI, the GS will authenticate the User, and then prompt the User to enter the User Code, which the GS will then use to identify the Create Grant request.

\[Editor: we may need to include interaction types for iOS and Android as the mobile OS APIs evolve.]

# RS Access {#RSAccess}

This document specifies three different mechanisms for the Client to access an RS ("bearer", "jose", and "jose+body"). The "bearer" mechanism is defined in {BearerToken}. The "jose" and "jose+body" mechanisms are proof-of-possession mechanisms and are defined in {{joseMech}} and {{jose_bodyMech}} respectively. Additional proof-of-possession mechanisms may be defined in other documents. The mechanism the Client is to use with an RS is the Response JSON authorization.mechanism attribute {{ResponseAuthorizationObject}}.

## Bearer Token {#BearerToken}

If the access mechanism is "bearer", then the Client accesses the RS per Section 2.1 of {{RFC6750}}

A non-normative example of the HTTP request headers follows:

    GET /calendar HTTP/2
    Host: calendar.example
    Authorization: bearer eyJJ2D6.example.access.token.mZf9pTSpA


# Error Responses {#ErrorResponses}

+ TBD

# JOSE Authentication {#JOSEauthN}

How the Client authenticates to the GS and RS are independent of each other. One mechanism can be used to authenticate to the GS, and a different mechanism to authenticate to the RS.

Other documents that specify other Client authentication mechanisms will replace this section.

In the JOSE Authentication Mechanism, the Client authenticates by using its private key to sign a JSON document with JWS per {{RFC7515}} which results in a token using JOSE compact serialization. 

\[Editor: are there advantages to using JSON serialization in the body?]

Different instances of a Registered Client MAY have different private keys, but each instance has a certificate to bind its private key to to a public key the GS has for the Client ID. An instance of a Client will use the same private key for all signing operations. 

The Client and the GS MUST both use HTTP/2 ({{RFC7540}}) or later, and TLS 1.3 ({{RFC8446}}) or later, when communicating with each other.

\[Editor: too aggressive to mandate HTTP/2 and TLS 1.3?]

The token may be included in an HTTP header, or as the HTTP message body.

The following sections specify how the Client uses JOSE to authenticate to the GS and RS.

## GS Access
The Client authenticates to the GS by passing either a signed header parameter, or a signed message body.
The following table shows the verb, uri and token location for each Client request to the GS:

| request            | http verb | uri          | token in     
|:---                |---        |:---          |:--- 
| Create Grant       | POST      | GS URI       | body
| Verify Grant       | PATCH     | Grant URI    | body 
| Read Grant         | GET       | Grant URI    | header 
| Update Grant       | PUT       | Grant URI    | body
| Delete Grant       | DELETE    | Grant URI    | header 
| Read AuthZ         | GET       | AZ URI       | header 
| Update AuthZ       | PUT       | AZ URI       | body 
| Delete AuthZ       | DELETE    | AZ URI       | header 
| GS Options         | OPTIONS   | GS URI       | header 
| Grant Options      | OPTIONS   | Grant URI    | header 
| AuthZ Options      | OPTIONS   | AZ URI       | header  


### Authorization Header

For requests with the token in the header, the JWS payload MUST contain the following attributes:

**iat** - the time the token was created as a NumericDate.

**jti** - a unique identifier for the token per {{RFC7519}} section 4.1.7.

**uri** - the value of the URI being called (GS URI, Grant URI, or AZ URI).

**verb** - the HTTP verb being used in the call ("GET", "DELETE", "OPTIONS")

The HTTP authorization header is set to the "jose" parameter followed by one or more white space characters, followed by the resulting token. 

A non-normative example of a JWS payload and the HTTP request follows:

    {
        "iat"   : 15790460234,
        "jti"   : "f6d72254-4f23-417f-b55e-14ad323b1dc1",
        "uri"   : "https://as.example/endpoint/grant/example6",
        "verb"  : "GET"
    }

    GET /endpoint/example.grant HTTP/2
    Host: as.example
    Authorization: jose eyJhbGciOiJIUzI1NiIsIn ...

\[Editor: make a real example token]

**GS Verification**

The GS MUST verify the token by:

+ TBD

### Signed Body

For requests with the token in the body, the Client uses the Request JSON as the payload in a JWS. The resulting token is sent with the content-type set to "application/jose".

A non-normative example (line breaks added to the body for readability):

    POST /endpoint HTTP/2
    Host: as.example
    Content-Type: application/jose
    Content-Length: 155

    eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyzdWIiOiIxMjM0NTY3ODkwIiwibmF
    tZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMe
    Jf36POk6yJV_adQssw5c

\[Editor: make a real example token]

**GS Verification**

The GS MUST verify the token by:

+ TBD

### Public Key Resolution

+ **Registered Clients** can use any of the JWS header values to direct the GS to resolve the public key matching the private key used to the Client ID. The GS MAY restrict with JWS headers a Client can use. 

\[Editor: would examples help here so that implementors understand the full range of options, and how an instance can have its own asymetric key pair]

A non-normative example of a JOSE header for a Registered Client with a key identifier of "12":

    {
        "alg"   : "ES256",
        "typ"   : "JOSE",
        "kid"   : "12"
    }

+ **Dynamic Clients** include their public key in the "jwk" JWS header. 

A non-normative example of a JOSE header for a Dynamic Client:

    {
        "alg"   : "ES256",
        "typ"   : "JOSE",
        "jwk"   : {
            "kty"   : "EC",
            "crv"   : "P-256",
            "x"     : "Kgl5DJSgLyV-G32osmLhFKxJ97FoMW0dZVEqDG-Cwo4",
            "y"     : "GsL4mOM4x2e6iON8BHvRDQ6AgXAPnw0m0SfdlREV7i4"
        }
    }

## RS Access

In the "jose" mechanism {{joseMech}}, all Client requests to the RS include a proof-of-possession token in the HTTP authorization header. In the "jose+body" mechanism {{jose_bodyMech}}, the Client signs the JSON document in the request if the POST or PUT verbs are used, otherwise it is the same as the "jose" mechanism. 

### JOSE header {#JWSHeader}

The GS provides the Client one or more JWS header parameters and values for a a certificate, or a reference to a certificate or certificate chain, that the RS can use to resolve the public key matching the private key being used by the Client.

A non-normative examples JOSE header:

    {
        "alg"   : "ES256",
        "typ"   : "JOSE",
        "x5u"   : "https://as.example/cert/example2"
    }


\[Editor: this enables Dynamic Clients to make proof-of-possession API calls the same as Registered Clients.]

### "jose" Mechanism {#joseMech}

The JWS payload MUST contain the following attributes:

**iat** - the time the token was created as a NumericDate.

**jti** - a unique identifier for the token per {{RFC7519}} section 4.1.7.

**uri** - the value of the RS URI being called.

**verb** - the HTTP verb being used in the call

**token** - the access token provided by the GS to the Client

The HTTP authorization header is set to the "jose" parameter followed by one or more white space characters, followed by the resulting token. 

A non-normative example of a JWS payload and the HTTP request follows:

    {
        "iat"   : 15790460234,
        "jti"   : "f6d72254-4f23-417f-b55e-14ad323b1dc1",
        "uri"   : "https://calendar.example/calendar",
        "verb"  : "GET",
        "token" : "eyJJ2D6.example.access.token.mZf9pTSpA"
    }

    GET /calendar HTTP/2
    Host: calendar.example
    Authorization: jose eyJhbG.example.jose.token.adks

\[Editor: make a real example token]

**RS Verification**

The RS MUST verify the token by:

+ verify access token is bound to the public key -- include key fingerprint in access token?
+ TBD

### "jose+body" Mechanism {#jose_bodyMech}

The "jose+body" mechanism can only be used if the content being sent to the RS is a JSON document. 

Any requests not sending a message body will use the "jose" mechanism {{joseMech}}. 

Requests sending a message body MUST have the following JWS payload:

**iat** - the time the token was created as a NumericDate.

**jti** - a unique identifier for the token per {{RFC7519}} section 4.1.7.

**uri** - the value of the RS URI being called.

**verb** - the HTTP verb being used in the call

**token** - the access token provided by the GS to the Client

**body** - the message body being sent to the RS

A non-normative example of a JWS payload and the HTTP request follows:

    {
        "iat"   : 15790460234,
        "jti"   : "f6d72254-4f23-417f-b55e-14ad323b1dc1",
        "uri"   : "https://calendar.example/calendar",
        "verb"  : "POST",
        "token" : "eyJJ2D6.example.access.token.mZf9pTSpA",
        "payload" : {
            "event" : {
                "title"             : "meeting with joe",
                "start_date_utc"    : "2020-02-21 11:00:00",
                "end_date_utc"      : "2020-02-21 11:00:00"
            }  
        }
    }

    POST /calendar HTTP/2
    Host: calendar.example
    Content-Type: application/jose
    Content-Length: 155

    eyJhbGciOi.example.jose+body.adasdQssw5c

\[Editor: make a real example token]

**RS Verification**

The RS MUST verify the token by:

+ TBD

### Public Key Resolution

The RS has a public key for the GS that it uses to verify the certificate or certificate chain the Client includes in the JWS header. 


## Request Encryption

\[Editor: to be fleshed out]

The Client encrypts a request when ??? using the GS public key returned as the ??? attribute in GS Options {{GSoptions}}.

## Response Signing 

\[Editor: to be fleshed out]

The Client verifies a signed response ??? using the GS public key returned as the ??? attribute in GS Options {{GSoptions}}.

## Response Encryption

\[Editor: to be fleshed out]

The Client decrypts a response when ??? using the private key matching the public key included in the request as the ??? attribute in {{RequestJSON}}.


# Extensibility {#Extensibility}

This standard can be extended in a number of areas:

+ **Client Authentication Mechanisms**

    + An extension could define other mechanisms for the Client to authenticate to the GS and/or RS such as Mutual TLS or HTTP Signing. Constrained environments could use CBOR {{RFC7049}} instead of JSON, and COSE {{RFC8152}} instead of JOSE, and CoAP {{RFC8323}} instead of HTTP/2.

+ **Grant**

    + An extension can define new objects in the Grant Request and Grant Response JSON. 

+ **Top Level**

    + Top level objects SHOULD only be defined to represent functionality other the existing top level objects and attributes.

+ **"client" Object**

    + Additional information about the Client that the GS would require related to an extension.

+ **"user" Object**

    + Additional information about the User that the GS would require related to an extension.

+ **"authorization" Object**

    + Additional types of authorizations in addition to OAuth 2.0 scopes and RAR.

+ **"claims" Object**

    + Additional types of identity claims in addition to OpenID Connect claims and Verified Credentials.

+ **Interaction types**

   + Additional types of interactions a Client can start with the User.


+ **Continuous Authentication**

    + An extension could define a mechanism for the Client to regularly provide continuous authentication signals and receive responses.

\[Editor: do we specify access token / handle introspection in this document, or leave that to an extension?]

\[Editor: do we specify access token / handle revocation in this document, or leave that to an extension?]

# Rational

1. **Why is there only one mechanism for the Client to authenticate with the GS? Why not support other mechanisms?**

    Having choices requires implementers to understand which choice is preferable for them. Having one default mechanism in the document for the Client to authenticate simplifies most implementations. Deployments that have unique characteristics can select other mechanisms that are preferable in specific environments. 

1. **Why is the default Client authentication JOSE rather than MTLS?**

    MTLS cannot be used today by a Dynamic Client. MTLS requires the application to have access below what is typically the application layer, that is often not available on some platforms. JOSE is done at the application layer. Many GS deployments will be an application behind a proxy performing TLS, and there are risks in the proxy passing on the results of MTLS.

1. **Why is the default Client authentication JOSE rather than HTTP signing?**

    There is currently no widely deployed open standard for HTTP signing. Additionally, HTTP signing requires passing all the relevant parts of the HTTP request to downstream services within an GS that may need to independently verify the Client identity.

1. **What are the advantages of using JOSE for the Client to authenticate to the GS and a resource?**
    
    Both Registered Clients and Dynamic Clients can have a private key, eliminating the public Client issues in OAuth 2.0, as a Dynamic Client can create an ephemeral key pair. Using asymetric cryptography also allows each instance of a Registered Client to have its own private key if it can obtain a certificate binding its public key to the public key the GS has for the Client. Signed tokens can be passed to downstream components in a GS or RS to enable independent verification of the Client and its request. The GS Initiated Sequence {{GSInitiatedGrant}} requires a URL safe parameter, and JOSE is URL safe.

1. **Why does the GS not return parameters to the Client in the redirect url?**

    Passing parameters via a browser redirection is the source of many of the security risks in OAuth 2.0. It also presents a challenge for smart devices. In this protocol, the redirection from the Client to the GS is to enable the GS to interact with the User, and the redirection back to the Client is to hand back interaction control to the Client if the redirection was a full browser redirect. Unlike OAuth 2.0, the identity of the Client is independent of the URI the GS redirects to.

1. **Why is there not a UserInfo endpoint as there is with OpenID Connect?**

    Since the Client can Read Grant at any time, it get the same functionality as the UserInfo endpoint, without the Client having to manage a separate access token and refresh token. If the Client would like additional claims, it can Update Grant, and the GS will let the Client know if an interaction is required to get any of the additional claims, which the Client can then start. 
       
    \[Editor: is there some other reason to have the UserInfo endpoint?]
    
1. **Why is there still a Client ID?**

    The GS needs an identifier to fetch the meta data associated with a Client such as the name and image to display to the User, and the policies on what a Client is allowed to do. The Client ID was used in OAuth 2.0 for the same purpose, which simplifies migration. Dynamic Clients do not have a Client ID. 

1. **Why have both claims and authorizations?**

    There are use cases for each that are independent: authenticating a user and providing claims vs granting access to a resource. A request for an authorization returns an access token which may have full CRUD capabilities, while a request for a claim returns the claim about the User -- with no create, update or delete capabilities. While the UserInfo endpoint in OIDC may be thought of as a resource, separating the concepts and how they are requested keeps each of them simpler in the Editor's opinion. :)

1. **Why specify HTTP/2 or later and TLS 1.3 or later for Client and GS communication in {{JOSEauthN}}?**

    Knowing the GS supports HTTP/2 enables a Client to set up a connection faster. HTTP/2 will be more efficient when Clients have large numbers of access tokens and are frequently refreshing them at the GS as there will be less network traffic. Mandating TLS 1.3 similarly improves the performance and security of Clients and GS when setting up a TLS connection.

1. **Why do some of the JSON objects only have one child, such as the identifiers object in the user object in the Grant Request?**

    It is difficult to forecast future use cases. Having more resolution may mean the difference between a simple extension, and a convoluted extension.

1. **Why is the "iss" included in the "oidc" identifier object? Would the "sub" not be enough for the GS to identify the User?**

    This decouples the GS from the OpenID Provider (OP). The GS identifier is the GS URI, which is the endpoint at the GS. The OP issuer identifier will likely not be the same as the GS URI. The GS may also provide claims from multiple OPs.

1. **Why complicate things with interaction.keep?**

    The common sequence has a back and forth between the Client and the GS, and the Client can update the Grant and have a new interaction. Keeping the interaction provides a more seamless user experience where the results from the first request determine subsequent requests. For example, a common pattern is to use a GS to authenticate the User at the Client, and to register the User at the Client using additional claims from the GS. The Client does not know a priori if the User is a new User, or a returning User. Asking a returning User to consent releasing claims they have already provided is a poor User experience, as is sending the User back to the GS. The Client requesting identity first enables the Client to get a response from the GS while the GS is still interacting with the User, so that the Client can request additional claims only if needed. Additionally, the claims a Client may want about a User may be dependent on some initial Claims. For example, if a User is in a particular country, additional or different Claims my be required by the Client.

    There are also benefits for the GS. Today, a GS usually keeps track of which claims a Client has requested for a User. Storing this information for all Clients a User uses may be undesirable for a GS that does not want to have that information about the User. Keeping the interaction allows the Client to track what information it has about the User, and the GS can remain stateless.

1. **Why is there a "jose+body" RS access mechanism method {{jose_bodyMech}} for the Client?** 

    There are numerous use cases where the RS wants non-repudiation and providence of the contents of an API call. For example, the UGS Service Supplier Framework for Authentication and Authorization {{UTM}}.

1. **Why use URIs to instead of handles for the Grant and Authorization?**

    A URI is an identifier just like a handle that can contain GS information that is opaque to the Client -- so it has all the features of a handle, plus it can be the URL that is resolved to manipulate a Grant or an Authorization. As the Grant URI and AZ URI are defined to start with the GS URI, the Client (and GS) can easily determine which GS a Grant or Authorization belong to. URIs also enable a RESTful interface to the GS functionality.

1. **Why use the OPTIONS verb on the GS URI? Why not use a .well-known mechanism?**

    Having the GS URI endpoint respond to the metadata allows the GS to provide Client specific results using the same Client authentication used for other requests to the GS. It also reduces the risk of a mismatch between what the advertised metadata, and the actual metadata. A .well-known discovery mechanism may be defined to resolve from a hostname to the GS URI.

1. **Why support UPDATE, DELETE, and OPTIONS verbs on the AZ URI?**

    Maybe there are no use cases for them \[that the editor knows of], but the GS can not implement, and they are available if use cases come up.


# Acknowledgments

This draft derives many of its concepts from Justin Richer's Transactional Authorization draft {{TxAuth}}. 

Additional thanks to Justin Richer and Annabelle Richard Backman for their strong critique of earlier drafts.

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

- major rewrite
- handles are now URIs
- the collection of claims and authorizations are a Grant
- an Authorization is its own type
- lots of sequences added

## draft-hardt-xauth-protocol-03

- fixed RO definition
- improved language in Rationals
- added user code interaction method, and aligned qrcode interaction method
- added completion_uri for code flows

## draft-hardt-xauth-protocol-04

- renamed interaction uris to have purpose specific names

## draft-hardt-xauth-protocol-05

- separated claims from identifiers in request user object
- simplified reciprocal grant flow
- reduced interactions to redirect and indirect
- simplified interaction parameters
- added in language for Client to verify interaction completion
- added Verify Grant API and Interaction Nonce
- replaced Refresh AuthZ with Read AuthZ. Read and refresh are same operation.

## draft-hardt-xauth-protocol-06

- fixup examples to match specification

# Comparison with OAuth 2.0 and OpenID Connect

**Changed Features**

The major changes between this protocol and OAuth 2.0 and OpenID Connect are:

+ The Client allows uses a private key to authenticate in this protocol instead of the client secret in OAuth 2.0 and OpenID Connect.

+ The Client initiates the protocol by making a signed request directly to the GS instead of redirecting the User to the GS.

+ The Client does not pass any parameters in redirecting the User to the GS, and optionally only receives an interaction nonce in the redirection back from the GS.

+ The refresh_token has been replaced with a AZ URI that both represents the authorization, and is the URI for obtaining a fresh access token.

+ The Client can request identity claims to be returned independent of the ID Token. There is no UserInfo endpoint to query claims as there is in OpenID Connect.

+ The GS URI is the token endpoint.

**Preserved Features** 

+ This protocol reuses the OAuth 2.0 scopes, Client IDs, and access tokens of OAuth 2.0. 

+ This protocol reuses the Client IDs, Claims and ID Token of OpenID Connect.

+ No change is required by the Client or the RS for accessing existing bearer token protected APIs.

**New Features**

+ A Grant represents both the user identity claims and RS access granted to the Client.

+ The Client can verify, update, retrieve, and delete a Grant.

+ The GS can initiate a flow by creating a Grant and redirecting the User to the Client with the Grant URI.

+ The Client can discovery if a GS has a User with an identifier before the GS interacts with the User.

+ The Client can request the GS to first authenticate the User and return User identity claims, and then the Client can update Grant request based on the User identity.

+ Support for scannable code initiated interactions.

+ Each Client instance can have its own private / public key pair.

+ Highly extensible per {{Extensibility}}.
