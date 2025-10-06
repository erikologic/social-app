package main

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"path/filepath"

	"github.com/flosch/pongo2/v6"
	"github.com/labstack/echo/v4"
)

type RendererLoader struct {
	prefix string
	fs     fs.FS
}

func NewRendererLoader(prefix string, fsys fs.FS) pongo2.TemplateLoader {
	return &RendererLoader{
		prefix: prefix,
		fs:     fsys,
	}
}
func (l *RendererLoader) Abs(_, name string) string {
	if filepath.HasPrefix(name, l.prefix) {
		return name
	}
	return filepath.Join(l.prefix, name)
}

func (l *RendererLoader) Get(path string) (io.Reader, error) {
	b, err := fs.ReadFile(l.fs, path)
	if err != nil {
		return nil, fmt.Errorf("reading template %q with prefix %q failed: %w", path, l.prefix, err)
	}
	return bytes.NewReader(b), nil
}

type Renderer struct {
	TemplateSet *pongo2.TemplateSet
	Debug       bool
}

func NewRenderer(prefix string, fsys fs.FS, debug bool) *Renderer {
	return &Renderer{
		TemplateSet: pongo2.NewSet(prefix, NewRendererLoader(prefix, fsys)),
		Debug:       debug,
	}
}

func (r Renderer) Render(w io.Writer, name string, data interface{}, c echo.Context) error {
	var ctx pongo2.Context

	if data != nil {
		var ok bool
		ctx, ok = data.(pongo2.Context)
		if !ok {
			return errors.New("no pongo2.Context data was passed")
		}
	}

	var t *pongo2.Template
	var err error

	t, err = r.TemplateSet.FromFile(name)
	if err != nil {
		return err
	}

	return t.ExecuteWriter(ctx, w)
}
