/*------ List of SQL Statements ---*/
const sql = {}


sql.query = {

    /*--------Login-----------*/
    login: 'SELECT * FROM Users WHERE username=$1',

    /*------Restaurant Staff--------*/
    restInfo: 'SELECT * FROM Restaurants R INNER JOIN RestaurantStaff RS on R.restaurantID =  RS.restaurantID WHERE RS.uid = $1 LIMIT 1',
    menuInfo: 'SELECT * FROM Food F INNER JOIN Restaurants R on F.restaurantID = R.restaurantID WHERE R.restaurantID = $1',
    // by default category is selected as 'Indian Cusine' by using \'
    insertFood: 'INSERT INTO Food(foodName, price, category, RestaurantID) Values($1, $2, \'Indian Cuisine\', $3)',

    


}

module.exports = sql;