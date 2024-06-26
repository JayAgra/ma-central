sudo apt-get update                                                     #
sudo apt-get install libssl-dev                                         # linux build requirements
sudo apt-get install pkg-config                                         #
mkdir macsvc && cd macsvc                                               # ~/macsvc
git clone "https://github.com/JayAgra/ma-central.git"                   # clone git repo
cd ma-central                                                           # ~/macsvc/ma-central (git repo)
git fetch --tags                                                        # get tags from remote
latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)    # get latest tag and set to variable latestTag
git checkout $latestTag                                                 # checkout latest tag (makes sure we have stable)
cd ../                                                                  # ~/macsvc
cp ma-central/Server/data.db data.db                                    # # #
cp ma-central/Server/data_auth.db data_auth.db                          # copy necessary files from git repo
cp ma-central/Server/.example.env .env                                  # # #
cp ma-central/Server/update.sh update.sh                                # copy update script
chmod +x update.sh                                                      # make it executatble
cp ma-central/Server/service.sh service.sh                              # copy service management script
chmod +x service.sh                                                     # make it executatble
mkdir ssl                                                               # create ssl directory for certificates
cd ma-central/Server                                                    # ~/macsvc/macsvc (git repo)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh          # install rust
source "$HOME/.cargo/env"                                               # source (needed if rust is newly installed)
cargo build -r                                                          # build release
cp target/release/macsvc ../../macsvc                                   # copy built object from target to macsvc
echo "###"                                                              #
echo "macsvc $latestTag is now installed"                               # print version number
echo "please edit the .env file in the new macsvc directory"            # edit the env file for program to run correctly
echo "cd macsvc && nano .env"                                           # guide user to editing .env
echo "###"                                                              #