cd ma-central                                                           # ~/macsvc/ma-central (assume start in ~/macsvc)
git pull                                                                # pull from origin
git fetch --tags                                                        # get tags
latestTag=$(git describe --tags `git rev-list --tags --max-count=1`)    # set latest tag to variable latestTag
git checkout $latestTag                                                 # checkout latest tag
cd Server                                                               # open server code
cargo build -r                                                          # build release (assume rust is already installed)
rm ../../macsvc                                                         # delete old binary
cp target/release/macsvc ../../macsvc                                   # copy built object from target to macsvc
echo "###"                                                              #
echo "macsvc is now updated to version $latestTag"                      # macsvc is now updated
echo "###"                                                              #