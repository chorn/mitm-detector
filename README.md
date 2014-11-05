# mitm-detector

## What is this stuff:

These tools are intended to detect various kinds of man-in-the-middle (M-I-T-M) attacks, or more practically, verify that you are not being subject to a M-I-T-M attack.

Here are the scripts you could probably use right now:

1. `ssl-grab-cert.sh` will download the SSL certificate from an HTTPS server.
1. `ssl-cert-info.sh` will print the interesting bits of a downloaded certificate.
1. `ssl-mitm-check.sh`
  1. Downloads an SSL certificate and compares it to a local, trusted copy, using fingerprints.
  1. You should make a trusted copy of a certificate first, using `ssl-grab-cert.sh`.
  1. Will also try to detect a captured network, wildcard certs, subjectAltNames with DNS entries, and do the right thing.

1. `transparent-proxy-check.sh` has a server-side dependency to work.
1. `content-tampering-check.sh` also has a server-side depedency.

## Why would you make this?

The practice of breaking SSL to perform logging and content filtering is a common feature of commerical/enterprise network hardware, and is not a new thing.  It requires more or less complete control of all of the computers within that network, so that each computer will "trust" the fact that SSL is being stripped, broken, replaced, or whatever feature-name-verb the vendor calls it.

Then I found out about the [Wifi Pineapple](https://wifipineapple.com) and I freaked out a little bit.  It looked to me like there were scenarios in which SSL could be replaced via M-I-T-M and you might not know.

Next, I searched for some way to detect these things, which made me freak out a little more.  The only resource I could find was from [Steve Gibson](https://www.grc.com), and it was [web based](https://www.grc.com/fingerprints.htm), which is fine, but not great if I wanted to use it as a scripting resource.

## How do I use this?

### My current use case is similar to this

Grab a certificate I trust:

    $ ./ssl-grab-cert.sh www.digitalocean.com
    Certificate written to: <path to wherever you put this>/certs/www.digitalocean.com.pem
    <some stuff about the certificate>

Then, I use [ControlPlane](http://www.controlplaneapp.com) to run a script whenever my network changes.  You don't need ControlPlane, you could just run it by hand:

    $ ./ssl-mitm-check.sh www.digitalocean.com
    OK

or    

    $ ./ssl-mitm-check.sh www.digitalocean.com
    Possible SSL M-I-T-M: <the fingerprint I trust> != <the fingerprint I just got>

or    

    $ ./ssl-mitm-check.sh www.digitalocean.com
    Host name doesn't match commonName: www.digitalocean.com != login.my_coffee_shop_with_captured_wifi.com
    Probable Captured Network : www.digitalocean.com != login.my_coffee_shop_with_captured_wifi.com

## This is dumb, just use a VPN

Ok that's a pretty good point.  But what if you can't?  What if you want to be able to test a network for bad things?

## TODO

I think the use of `nping` to detect a transparent proxy is still the way to go.  I suspect the test should be longer running.  I know that there should be a heuristic or at least a better metric than what I've got now.

I'd like to be able to run a test to see if a hop on my network, or something inside my ISP is altering the content of a webpage before I receive it.


## Credits, Thanks, and References

* [Steve Gibson](https://www.grc.com) for his SSL Fingerprinting tool.  I think his write-up on the problem is probably excellent as well.  I didn't read it of course, as soon as I saw "fingerprint" I went all neckbeard and did my own thing.
* Apologies to everyone at @nickelcityruby, where I was a little obsessed with the transparent proxy things and had clearly left my tinfoil hat at home.
* Thanks to @wayneeseguin, for pairing with me, being nice enough to not tell me I wasn't making a lot of sense, and not pointing out that we were deeply into doing whatever the antonym of yak shaving is.
* I think that doing bad things with [RFC 3143](http://tools.ietf.org/html/rfc3143) might be a simpler/faster/easier/KISS approach to detecting a proxy.


