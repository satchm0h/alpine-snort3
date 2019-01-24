# alpine-snort3

<p align="center">
  <img height="200" src="https://www.dropbox.com/s/0q7h9z5kjm9x194/Snort3.png?dl=1"/>
  <br/>
  <a href="snort.org/snort3">
    <span style='font-size: x-large;'>snort.org/snort3</span>
  </a>
</p>

## Alpine Linux Snort 3 Runtime

### TL;DR

`docker run -it --rm satchm0h/alpine-snort3 snort --version`

or

`docker run -it --rm satchm0h/alpine-snort3 ash`

...if you want to see what's in there. Hint, look in `/usr/local/`

### Wait...what is this thing for?

This image is intentionally basic. It is intended to provide a clean (thin-ish) base layer upon which to build a functional Snort 3 service container tailored to your use case. YMMV

The Dockerfile leverages a multi-stage build from the Snort3 source in order to build a minimally sized base container upon which you can add your own special sauce

If you are looking for an image to hack on the Snort 3 source code, [go check out Xiche's dockerhub repositories](https://hub.docker.com/u/xiche). He's got coverage for a number of linux distros.

### To Do

My goal is to set up automated builds tracking the [Snort 3 repo](https://github.com/snort3/snort3) in the near future.