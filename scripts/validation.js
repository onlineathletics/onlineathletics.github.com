/* 
 * IntelliJustice Intelligent Referee Assistant System
 *
 * The MIT License
 *
 * Copyright 2011-2014 Andrey Pudov.
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

/**
 * The collection of validation functions used in client side validation.
 *
 * @author    Andrey Pudov        <mail@andreypudov.com>
 * @version   0.00.00
 * %name      validation.js
 * %date      11:40:00 AM, Jan 06, 2014
 */

/* the list of commonly used constants */
var CONTACT_NAME_MAX_LENGTH    = 255;
var CONTACT_EMAIL_MAX_LENGTH   = 255;
var CONTACT_MESSAGE_MAX_LENGTH = 4096;

var MESSAGE_MIN_OFFSET = 200;

var EMAIL_REGULAR_EXPRESSION = /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

/* the element top offest used in scroll animation */
//var FOCUS_OFFSET = 24;

var VALIDATION_POPOVER_OPTIONS = {
    placement: function(context, source) {
        var position = $(source).offset();

        return (position.left > MESSAGE_MIN_OFFSET) 
            ? 'left'
            : 'top';
    },

    trigger: 'manual'
};

/**
 * Validates contacts form and returns true if form data is correct, and false
 * otherwise.
 * 
 * @return {Boolean} the validation status.
 */
function validateContactForm() {
    var $nameField    = $('#contactForm\\:contactInputName');
    var $emailField   = $('#contactForm\\:contactInputEmail');
    var $textArea     = $('#contactForm\\:contactTextArea');
    var $submitButton = $('#contactForm\\:submitButton');
    
    var status =  validateText($nameField, CONTACT_NAME_MAX_LENGTH);
    status     &= validateEmail($emailField);
    status     &= validateText($textArea, CONTACT_MESSAGE_MAX_LENGTH);
    status     =  Boolean(status);
    
    $submitButton.parent().toggleClass('disabled', status);

    return status;
}

/**
 * Validates a value of input text field and if the value is emptry sets error
 * style class and returns false, otherwise return true.
 * 
 * @param {Element} field   the input text field.
 * @param {Number}  length  the maximumlength of the text vfield alue.
 * 
 * @return {Boolean}        true if text field value is valid, false otherwise.
 */
function validateText(field, length) {
    var $field = $(field);
    var $group = $field.parent();     
    var style  = ($field.prop('tagName').toUpperCase() === 'INPUT' 
        ? 'input-group has-error' : 'has-error');

    return !(stringIsEmpty($field, $group, style, getMessage($group, '.validation-missing'))
          || stringIsOverlong($field, $group, length, style, getMessage($group, '.validation-overlong')));
}

/**
 * Validates given text field, and returns true if a text field value is 
 * a correct email address. Otherwise returns false.
 * 
 * @param {Element} field the input text field.
 * 
 * @return {Boolean}      true if text field value is valid, false otherwise.
 */
function validateEmail(field) {
    var $field = $(field);
    var $group = $field.parent();
    var  style = 'input-group has-error';
    
    return !(stringIsEmpty($field, $group, style, getMessage($group, '.validation-missing'))
          || !isValidEmail($field, $group, style, getMessage($group, '.validation-invalid'))
          || stringIsOverlong($field, $group, CONTACT_EMAIL_MAX_LENGTH, style, 
                             getMessage($group, '.validation-overlong')));
}

/**
 * Validates specified input field and returns true if input value is empty.
 * 
 * @param {Element} $field  the input field to validate.
 * @param {Element} $group  the form group where input field from.
 * @param {String}  style   the error style for the form group.
 * @param {String}  message the error message.
 * 
 * @return {Boolean}        true if value is empty and false otherwise.
 */
function stringIsEmpty($field, $group, style, message) {
    var status = ($field.val() === '');
    
    togglePopover($group, style, message, status);
    
    return status;
}

/**
 * Validates specified input field and returns true if input value string is
 * longer than specified length.
 * 
 * @param {Element} $field  the input field to validate.
 * @param {Element} $group  the form group where input field from.
 * @param {Number}  length  the maximum allowed length.
 * @param {String}  style   the error style for the form group.
 * @param {String}  message the error message.
 * 
 * @return {Boolean}        true if value is longer than specified length, 
 *                          and false otherwise.
 */
function stringIsOverlong($field, $group, length, style, message) {
    var status = ($field.val().length > length);
    
    togglePopover($group, style, message, status);
    
    return status;
}

/**
 * Validates specified input field and returns true if input value string is
 * valid email address.
 * 
 * @param {Element} $field  the input field to validate.
 * @param {Element} $group  the form group where input field from.
 * @param {String}  style   the error style for the form group.
 * @param {String}  message the error message.
 * 
 * @return {Boolean}        true if value is valid email address, 
 *                          and false otherwise.
 */
function isValidEmail($field, $group, style, message) {
    var status = EMAIL_REGULAR_EXPRESSION.test($field.val());
    
    togglePopover($group, style, message, !status);
    
    return status;
}

/**
 * Returns the message for a specific selector inside a form validation  group.
 * 
 * @param {Element} $groupd  the form group.
 * @param {String}  selector the CSS selector of the message.
 * 
 * @return {String}          the message text.
 */
function getMessage($groupd, selector) {
    return $groupd.children(selector).text();
}

/**
 * Toggles popover for a specific validation function. Shows popover and changes
 * form group style to error when status is true, and returns normal style, 
 * as well as, hides popover otherwise.
 * 
 * @param {Element} $group  the form group where input field from.
 * @param {String}  style   the error style for the form group.
 * @param {String}  message the error message.
 * @param {Boolean} status  the validation status.
 */
function togglePopover($group, style, message, status) {
    var options  = VALIDATION_POPOVER_OPTIONS;
        options.content = message;
    var $popover    = $group.popover().popover('destroy');
        $popover    = $group.popover(options);
    
    $group.toggleClass(style, status);    
    $popover.popover(status ? 'show' : 'hide');
}