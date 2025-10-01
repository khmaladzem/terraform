#!/bin/bash
sudo adduser mkhmaladze
sudo echo "mkhmaladze ALL=(root) NOPASSWD: ALL" | sudo tee  "/etc/sudoers.d/mkhmaladze"
sudo mkdir -p /home/mkhmaladze/.ssh
sudo chmod 700 /home/mkhmaladze/.ssh
sudo echo 'ssh-rsa ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDG5GpbZ0cUBDSLWV63pGhyNazU7txtIEAToBIT9Qa72BeGVB5kPDhRYI2xx80aFmT5WycA//wMoU8a1uBwIF44TRBS7WtiP6UzEZefpcj7IvEPDhEm2UE7QluQSqtWDzyMF+rxkeLNVo7uMJ9sZt/d82S+8y+MR+CLzzwjYrSCdphrCZoaNMePfU3nbbeWda/jNLmjLziincY9Yt7VlDTijiuGb2M3Tij8sbJYKvrEHDy/XV+yRyANtp3iTCIVdJ9k0Qan8wa7qYRvIfbrD6XlqMD5isdkLeA5Yd3GLtLTCt447yBo/QDt7ZM91T7fNZRkzbgoW5IRC+Q44dKkYE3qe3E93lZ/IHKK9iYDVbnj6V1ZzUZ0eDqv7eA9yKWNTg7dO4zqdl2PkxF5Icj8B9v5btE1QMXj8SDUP1FV+G6RGaxVEf7Y8MMuxoD3FVJ4nsQrOhFeDBcn6c5BxOMttWAPnTyu/FMvOE7z1JFY8fp+VClrzIY0tiIC0X3pwyg7UmJ3GKY5RpGKvKxvNWUDjzVGjiHyDRDTvd33UrlMEZFTVKJ4/fIVR2xjeE2WUegSrZVKyPOYF10tkV7EBmjNBCgJtm954Ufea2Dts5q5bhSdQwe02dvdJaQe2ykl7Tk5pu57HYOzisi3UDmuByiOfU5IpADUWfJ57BeMs5Mhr7gc9w== khmaladzemikheil7@gmail.com' | sudo tee '/home/mkhmaladze/.ssh/authorized_keys'
sudo chmod 600 /home/mkhmaladze/.ssh/authorized_keys
sudo chown mkhmaladze:mkhmaladze /home/mkhmaladze/.ssh -R
sudo usermod -aG wheel, mkhmaladze