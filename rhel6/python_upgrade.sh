```
#!/bin/bash
sudo yum install python
sudo yum -y update
sudo cd /usr/src
sudo yum install gcc
sudo yum install -y python-setuptools
sudo wget https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tgz
sudo tar xf Python-2.7.9.tgz
sudo mv Python-2.7.9 python27
sudo cd python27
sudo ./configure
sudo make altinstall
echo "python-2.7 -V"
```
