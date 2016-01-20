# xlmm dockerfile
FROM ubuntu:14.04
MAINTAINER aladdinwang <aladdin_wang@aliyun.com>

ADD Python-2.7.11.tar.xz /tmp
ADD get-pip.py /tmp
ADD Imaging-1.1.7.tar.gz /tmp
ADD resolv.conf /tmp
ADD requirements.txt /tmp

RUN cp -f /tmp/resolv.conf /etc/resolv.conf

# remove several traces of python
RUN apt-get purge -y python.*

# http://bugs.python.org/issue19846
# > At the moment, setting "LANG=C" on a Linux system *fundamentally breaks Python 3*, and that's not OK.
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
		ca-certificates \
		libsqlite3-0 \
		libssl1.0.0 \
	&& rm -rf /var/lib/apt/lists/*


# if this is called "PIP_VERSION", pip explodes with "ValueError: invalid truth value '<VERSION>'"
ENV PYTHON_PIP_VERSION 7.1.2

RUN set -ex \
	&& buildDeps=' \
		curl \
		gcc \
		libbz2-dev \
		libc6-dev \
		libncurses-dev \
		libreadline-dev \
		libsqlite3-dev \
		libssl-dev \
		make \
		xz-utils \
                zlibc \
		zlib1g-dev \
                libssl-dev \
                libssl0.9.8 \
                libjpeg8-dev \
                libfreetype6-dev \
                libmysqlclient-dev \
                libxml2-dev \
                libxslt1-dev \
	' \
	&& apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/*

RUN ln -s /usr/lib/x86_64-linux-gnu/libjpeg.so /usr/lib \
    && ln -s /usr/lib/x86_64-linux-gnu/libfreetype.so /usr/lib \
    && ln -s /usr/lib/x86_64-linux-gnu/libz.so /usr/lib

RUN cd /tmp/Python-2.7.11 \
       && ./configure --enable-shared --enable-unicode=ucs4 \
       && make -j$(nproc) \
       && make install \
       && ldconfig \
       && cd /tmp \
       && python2 get-pip.py \
       && pip install --no-cache-dir --upgrade pip==$PYTHON_PIP_VERSION \
       && find /usr/local \
		\( -type d -a -name test -o -name tests \) \
		-o \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
		-exec rm -rf '{}' + \
       && apt-get purge -y --auto-remove $buildDeps \
       && rm -rf /tmp/Python-2.7.11

RUN cd /usr/include \
    && ln -s freetype2 freetype

RUN cd /tmp/Imaging-1.1.7 \
    && python setup.py build_ext -i \
    && python setup.py install

RUN cd /tmp \
    && pip install -r requirements.txt

ADD django_admin.tar.gz /usr/local/lib/python2.7/site-packages/django/contrib/admin

ENTRYPOINT ["python2"]
CMD ["manage.py", "runserver", "0.0.0.0:8000", "--traceback"]