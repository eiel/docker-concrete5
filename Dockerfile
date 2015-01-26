FROM php:5.6-apache

RUN apt-get update && apt-get install -y rsync && rm -r /var/lib/apt/lists/*

RUN a2enmod rewrite


# install the PHP extensions we need
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd
RUN docker-php-ext-install mysqli
RUN docker-php-ext-install mysql
RUN docker-php-ext-install mbstring

VOLUME /var/www/html

RUN apt-get update && apt-get install -y unzip && rm -r /var/lib/apt/lists/*
RUN curl -o concrete5.zip http://concrete5-japan.org/files/1114/1982/1355/concrete5.6.3.2.ja.zip && \
	unzip concrete5.zip -d /usr/src && \
	mv /usr/src/concrete5.* /usr/src/concrete5 && \
	rm concrete5.zip

COPY docker-entrypoint.sh /entrypoint.sh
RUN useradd -u 1000 apache && sed -i -e 's/^User www-data/User apache/' /etc/apache2/apache2.conf && sed -i -e 's/^Group www-data/Group staff/' /etc/apache2/apache2.conf

# grr, ENTRYPOINT resets CMD now
ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
