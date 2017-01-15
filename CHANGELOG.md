# Changelog
### v.0.0.3 (2017/01/15)
* Add default value 'localhost' to -h param
* Improve touching primary by `count(*) where non_index_file = 0` instead of `sum(id)` <br/>
 [Reason](./CHANGE_SUM_TO_COUNT.md)


### v.0.0.2 (2017/01/14)
* Change check type_primary? condition to regardless to field type
* Add `char` to regex of checking type_var_char? condition

### v.0.0.1 (2017/01/12)
* First release