bsdmail_install_packages() {
	pkg update
	pkg install -y $install_core
}

