```
cd /usr/src
yum install gcc
wget https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tgz
tar xf Python-2.7.9.tgz
mv Python-2.7.9 python27
cd python27
./configure
make altinstall
python-2.7 -V
```
