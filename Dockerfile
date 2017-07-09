FROM gentoo/stage3-amd64-nomultilib

RUN emerge-webrsync

RUN printf "en_US ISO-8859-1\nen_US.UTF-8 UTF-8\nen_GB.UTF-8 UTF-8\n" >> /etc/locale.gen && locale-gen

RUN printf "INPUT_DEVICES=\"evdev synaptics\"\nVIDEO_CARDS=\"fbdev\"\nFEATURES=\"-usersandbox\"\n" >> /etc/portage/make.conf

RUN printf "sys-fs/udev gudev" >> /etc/portage/package.use/udev

ENV USE -gnome -kde -minimal -qt4 dbus jpeg lock session startup-notification thunar udev X server gtk

ENV PORTAGE_INSTALL_LIST \
                         =dev-scheme/guile-2.0.14 \
                         blender \
                         bmon \
                         boost \
                         configobj \
                         dev-python/pip \
                         fish \
                         flaggie \
                         flex \
                         freecad \
                         geany \
                         gentoolkit \
                         glances \
                         glfw \
                         htop \
                         jinja \
                         dev-util/lemon \
                         libepoxy \
                         mesa \
                         meshlab \
                         mlocate \
                         dev-util/ninja \
                         numpy \
                         qtconcurrent \
                         qtcore \
                         qtnetwork \
                         qtopengl \
                         qtwidgets \
                         scipy \
                         sed \
                         supervisor \
                         sympy \
                         tigervnc \
                         vim \
                         x11vnc \
                         xfce4-meta \
                         xfce4-terminal

RUN emerge layman && layman -S && echo -ne 'y\n' | layman --nocheck -q -a cg

RUN emerge -uDN --with-bdeps=y --autounmask-write $PORTAGE_INSTALL_LIST || true && dispatch-conf -u && etc-update --automode -5

RUN emerge -uDN --with-bdeps=y $PORTAGE_INSTALL_LIST

RUN pip install --user hashids

RUN mkdir /root/.vnc && chown -R root:root /root/.vnc && touch /root/.vnc/xstartup

RUN printf "#!/bin/sh\nstartxfce4 &\n" >> /root/.vnc/xstartup && chmod a=rwx /root/.vnc/xstartup

RUN echo "p4ssw0rd" | vncpasswd -f > /root/.vnc/passwd && chmod 0600 /root/.vnc/passwd

RUN env-update && source /etc/profile

RUN cd /opt && git clone --depth=1 https://github.com/mkeeter/ao.git

RUN cd /opt/ao && mkdir build && cd build && cmake -G Ninja .. && ninja

RUN cd /opt && git clone --depth=1 https://github.com/mkeeter/antimony.git

RUN sed -i 's/foreach (PYTHON_NAME python3 python-py35 python-py34)/foreach (PYTHON_NAME python python-py35 python-py34)/g' /opt/antimony/CMakeLists.txt

RUN cd /opt/antimony && mkdir build && cd build && cmake -DCMAKE_PREFIX_PATH=/usr/include/qt5/QtCore -G Ninja .. && ninja && ninja install

RUN printf "[supervisord]\n[program:tigervnc]\ncommand=/usr/bin/vncserver\n" > /opt/supervisord.conf

CMD ["supervisord", "-n", "-c", "/opt/supervisord.conf"]
