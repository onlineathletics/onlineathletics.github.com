#!/bin/sh
exec scala "$0" "$@"
!#

/*
 * IntelliJustice Intelligent Referee Assistant System
 *
 * The MIT License
 *
 * Copyright 2011-2015 Andrey Pudov.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import scala.collection.mutable.MutableList
import sys.process._
import scala.language.postfixOps
import scala.io.Source
import scala.util.control.Breaks._

import java.awt.geom.AffineTransform
import java.awt.image.{AffineTransformOp, BufferedImage}
import java.io.{File, FileInputStream, FileNotFoundException}
import javax.imageio.ImageIO
import java.nio.file.{Paths, Files}
import java.nio.charset.StandardCharsets
import java.text.{SimpleDateFormat, ParseException}
import java.util.Properties
import java.util.regex.{Pattern, Matcher}

/**
 * Compiles website content.
 *
 * @author    Andrey Pudov        <mail@andreypudov.com>
 * @version   0.00.00
 * %name      compile.scala
 * %date      12:10:00 PM, Nov 28, 2014
 */
object Compile {
  val PAGES_SOURCE_LOCATION   = "source/pages"

  val LIBRARIES_LOCATION      = "libraries"
  val PAGES_LOCATION          = "p"
  val SCHEMAS_LOCATION        = "schemas"
  val SOURCE_LOCATION         = "source"
  val METADATA_LOCATION       = "source/metadata"

  val BOOTSTRAP_LOCATION      = LIBRARIES_LOCATION + "/bootstrap"
  val BOOTSTRAP_LESS_LOCATION = BOOTSTRAP_LOCATION + "/less/bootstrap.less"
  val BOOTSTRAP_CSS_LOCATION  = BOOTSTRAP_LOCATION + "/css/bootstrap.css"

  val IGNORE_NAMES            = Array("iPod Photo Cache", ".DS_Store")

  def compileStylesheet() {
    print("Compile style sheets...\t\t")

    val status = (("lessc " + BOOTSTRAP_LESS_LOCATION) #> new File(BOOTSTRAP_CSS_LOCATION)).!
    if (status != 0) {
      println("[FAILED]")
      sys.exit(status)
    }

    println("[SUCCESS]")
  }

  def compilePages() {
    print("Compiling pages...\t\t")

    println("[SUCCESS]")
  }

  def compileSchemas() {
    print("Compile schemas...\t\t")

    val layout  = Source.fromFile(SCHEMAS_LOCATION + File.separator + "layout.html").mkString
    val header  = Source.fromFile(SCHEMAS_LOCATION + File.separator + "header.html").mkString
    val content = Source.fromFile(SCHEMAS_LOCATION + File.separator + "content.html").mkString
    val footer  = Source.fromFile(SCHEMAS_LOCATION + File.separator + "footer.html").mkString

    val sources = new File(SOURCE_LOCATION).listFiles() ++ new File(PAGES_SOURCE_LOCATION).listFiles()

    sources.foreach(source =>
      if (source.isFile() && (IGNORE_NAMES.contains(source.getName()) == false)) {
        val text = Source.fromFile(source).mkString

        var _index   = 0
        var _layout  = layout
        var _title   = "<title>Andrey Pudov</title>"
        var _styles  = ""
        var _header  = header
        var _content = content
        var _footer  = footer
        var _scripts = ""
        var _block   = ""

        _block = "<define name='title'>"
        _index = text.indexOf(_block)
        if (_index >= 0) {
          _title = text.substring(_index + _block.length, text.indexOf("</define>", _index)).trim()
        }

        _block = "<define name='styles'>"
        _index = text.indexOf(_block)
        if (_index >= 0) {
          _styles = text.substring(_index + _block.length, text.indexOf("</define>", _index)).trim()
        }

        _block = "<define name='header'>"
        _index = text.indexOf(_block)
        if (_index >= 0) {
          _header = text.substring(_index + _block.length, text.indexOf("</define>", _index)).trim()
        }

        _block = "<define name='content'>"
        _index = text.indexOf(_block)
        if (_index >= 0) {
          _content = text.substring(_index + _block.length, text.indexOf("</define>", _index)).trim()
        }

        _block = "<define name='footer'>"
        _index = text.indexOf(_block)
        if (_index >= 0) {
          _footer = text.substring(_index + _block.length, text.indexOf("</define>", _index)).trim()
        }

        _block = "<define name='scripts'>"
        _index = text.indexOf(_block)
        if (_index >= 0) {
          _scripts = text.substring(_index + _block.length, text.indexOf("</define>", _index)).trim()
        }

        /* insert images to content block */
        val pattern = Pattern.compile("<insert name=\"image\" value=\".*\" \\/>", Pattern.CASE_INSENSITIVE)
        val matcher = pattern.matcher(_content)
        val buffer  = new StringBuffer()
        while (matcher.find()) {
          val image = _content.substring(matcher.start() + "<insert name=\"image\" value=\"".length(),
            matcher.end() - "\\/>".length() - 1)
          val album = image.substring(0, image.lastIndexOf('_'))
          val alt   = _title.replace("<title>", "").replace("</title>", "")

          matcher.appendReplacement(buffer, image.startsWith("PAGE_") match {
            case true  => getImageTag("images/pages/"  + image, "", false, alt)
            case false => getImageTag("albums/" + album + "/" + image, "", true, alt)
          })
        }
        matcher.appendTail(buffer)
        _content = buffer.toString()

        _footer = _footer.replace("<insert name='scripts' />", _scripts)

        _layout = _layout.replace("<insert name='title' />",   _title)
        _layout = _layout.replace("<insert name='styles' />",  _styles)
        _layout = _layout.replace("<insert name='header' />",  _header)
        _layout = _layout.replace("<insert name='content' />", _content)
        _layout = _layout.replace("<insert name='footer' />",  _footer)

        if (source.getPath().startsWith("source/pages/")) {
          _layout = _layout.replace("href='", "href='../")
          _layout = _layout.replace("src='",  "src='../")

          /* do not change external links */
          _layout = _layout.replace("href='../http", "href='http")
          _layout = _layout.replace("src='../http",  "src='http")

          Files.write(Paths.get("p" + File.separator + source.getName()), _layout.getBytes(StandardCharsets.UTF_8))
        } else {
          /* relative locationf for 404 page */
          if (source.getPath().startsWith("source/404.html")) {
            _layout = _layout.replace("href='", "href='/")
            _layout = _layout.replace("src='",  "src='/")
          }

          Files.write(Paths.get(source.getName()), _layout.getBytes(StandardCharsets.UTF_8))
        }
    })

    println("[SUCCESS]")
  }

  def getImageTag(photograph: String, prefix: String, postfix: Boolean, alt: String) : String = {
    def isVertical(name: String): Boolean = {
      val image  = ImageIO.read(new File(name + (postfix match {case true => "_small" case false => ""}) + ".jpg"))
      val width  = image.getWidth()
      val height = image.getHeight()

      return (height > width)
    }

    if (isVertical(photograph) == false) {
      return "<img src='" + prefix + photograph +
        (postfix match {case true => "_large" case false => ""}) + ".jpg' " +
        "alt='" + alt + "' class='img-responsive gallery-image'>"
    } else {
      return "<div class='gallery-container'>" +
        "\t<img src='" + prefix + photograph +
          (postfix match {case true => "_large" case false => ""}) + ".jpg' " +
          "alt='" + alt + "' class='img-responsive gallery-image gallery-image-vertical'>" +
        "</div>"
    }
  }

  def main(args: Array[String]) {
    compileStylesheet()
    compilePages()
    compileSchemas()
  }
}
