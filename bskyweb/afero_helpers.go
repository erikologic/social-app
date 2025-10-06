package bskyweb

import (
	"io/fs"
	"os"
	"path/filepath"

	"github.com/spf13/afero"
)

func NewCachedDirFS(sourceDir string) fs.FS {
	absPath := sourceDir
	if !filepath.IsAbs(sourceDir) {
		wd, err := os.Getwd()
		if err == nil {
			absPath = filepath.Join(wd, sourceDir)
		}
	}
	baseFS := afero.NewBasePathFs(afero.NewOsFs(), absPath)
	cacheFS := afero.NewMemMapFs()
	cachedFS := afero.NewCacheOnReadFs(baseFS, cacheFS, 0)
	return afero.NewIOFS(cachedFS)
}
