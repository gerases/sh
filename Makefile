release=9
dotarball=0
enablenetwork=1
repo=syseng-rpms
gem_name=sh

.PHONY: download
download:
	(mkdir -p src && cd src && gem fetch ${gem_name} -v ${_mkrpm_rpm_version})
