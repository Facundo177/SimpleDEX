// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
//function balanceOf(address account) external view returns (uint256);
//function transfer(address to, uint256 value) external returns (bool);
//function approve(address spender, uint256 value) external returns (bool);
//function transferFrom(address from, address to, uint256 value) external returns (bool);

contract SimpleDEX {
    address public owner;
    address public addressTokenA;
    address public addressTokenB;
    IERC20 private tokenA;
    IERC20 private tokenB;

    mapping (address => uint) private poolDeLiquidez;

    // Definición de modificadores
    modifier onlyOwner() {
        require(msg.sender == owner, "Solo el propietario puede ejecutar esta funcion.");
        _; // Continúa con la ejecución de la función modificada
    }


    // Definición de eventos
    // Se emite cuando se añade liquidez.
    event LiquidityAdded(uint256 indexed amountAddedTokenA, uint256 indexed amountAddedTokenB, uint256 totalTokenA, uint256 totalTokenB);
    // Se emite cuando se realiza un intercambio.
    event TokensSwapped(address indexed user, address FromToken, uint256 amountOffered, address ToToken, uint256 amountReceived);
    // Se emite cuando se retira liquidez.
    event LiquidityRemoved(uint256 indexed amountRemovedTokenA, uint256 indexed amountRemovedTokenB, uint256 totalTokenA, uint256 totalTokenB);


    // Funciones
    constructor(address _owner, address _tokenA, address _tokenB){
        // Establece el dueño del contrato al ser desplegado
        owner = _owner;
        // Guardo las addresses de las tokens
        addressTokenA = _tokenA;
        addressTokenB = _tokenB;
        // Interfaces para interactuar con las tokens
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }


    // Función que añade liquidez al pool, solo puede hacerlo el owner de este contrato
    function addLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(tokenA.balanceOf(msg.sender) >= amountA && tokenB.balanceOf(msg.sender) >= amountB, "No puede agregar un balance mayor al que posee.");

        // Aprobación para poder retirar las tokens
        bool isAapproved = tokenA.approve(msg.sender, amountA);
        bool isBapproved = tokenB.approve(msg.sender, amountB);
        require(isAapproved && isBapproved, "Transaccion no aprobada.");

        // Retiro de las tokens de la billetera del owner
        bool didAtransfer = tokenA.transferFrom(msg.sender, address(this), amountA);
        bool didBtransfer = tokenB.transferFrom(msg.sender, address(this), amountB);
        require(didAtransfer && didBtransfer, "No se pudo realizar la transferencia.");

        // Actualizo el mapeo de los balances de ambas tokens
        poolDeLiquidez[addressTokenA] = tokenA.balanceOf(address(this));
        poolDeLiquidez[addressTokenB] = tokenB.balanceOf(address(this));

        // Evento
        emit LiquidityAdded(amountA, amountB, poolDeLiquidez[addressTokenA], poolDeLiquidez[addressTokenB]);
    }


    function swapAforB(uint256 amountAIn) external {
        require(tokenA.balanceOf(msg.sender) >= amountAIn, "No tiene el balance suficiente de TokenA.");

        // Aprobación para poder retirar las tokens A
        bool isAapproved = tokenA.approve(msg.sender, amountAIn);
        require(isAapproved, "Transaccion no aprobada.");

        // Retiro de las tokens de la billetera del usuario
        bool didTransferFrom = tokenA.transferFrom(msg.sender, address(this), amountAIn);
        require(didTransferFrom, "No se pudo realizar la transferencia.");

        // Cálculos para la conversión
        uint256 A0 = tokenA.balanceOf(address(this));
        uint256 B0 = tokenB.balanceOf(address(this));
        uint256 dB = B0 - ((A0 * B0) / (A0 + amountAIn));

        // Actualizo el mapeo de los balances de ambas tokens (antes de transferirle al usuario)
        poolDeLiquidez[addressTokenA] += amountAIn;
        poolDeLiquidez[addressTokenB] -= dB;

        // Transferencia de las tokens B
        bool didTransfer = tokenB.transfer(msg.sender, dB);
        require(didTransfer, "No se pudo realizar el cambio de tokens.");

        // Evento
        emit TokensSwapped(msg.sender, addressTokenA, amountAIn, addressTokenB, dB);
    }


    function swapBforA(uint256 amountBIn) external {
        require(tokenB.balanceOf(msg.sender) >= amountBIn, "No tiene el balance suficiente de TokenB.");

        // Aprobación para poder retirar las tokens B
        bool isBapproved = tokenB.approve(msg.sender, amountBIn);
        require(isBapproved, "Transaccion no aprobada.");

        // Retiro de las tokens de la billetera del usuario
        bool didTransferFrom = tokenB.transferFrom(msg.sender, address(this), amountBIn);
        require(didTransferFrom, "No se pudo realizar la transferencia.");

        // Cálculos para la conversión
        uint256 A0 = tokenA.balanceOf(address(this));
        uint256 B0 = tokenB.balanceOf(address(this));
        uint256 dA = A0 - ((A0 * B0) / (B0 + amountBIn));

        // Actualizo el mapeo de los balances de ambas tokens (antes de transferirle al usuario)
        poolDeLiquidez[addressTokenA] -= dA;
        poolDeLiquidez[addressTokenB] += amountBIn;

        // Transferencia de las tokens A
        bool didTransfer = tokenA.transfer(msg.sender, dA);
        require(didTransfer, "No se pudo realizar el cambio de tokens.");

        // Evento
        emit TokensSwapped(msg.sender, addressTokenB, amountBIn, addressTokenA, dA);
    }


    function removeLiquidity(uint256 amountA, uint256 amountB) external onlyOwner {
        require(tokenA.balanceOf(address(this)) >= amountA && tokenB.balanceOf(address(this)) >= amountB, "No puede remover una liquidez mayor a la depositada en el contrato.");

        // Transfiere las tokens del contrato a la billetera del owner
        bool didAtransfer = tokenA.transfer(msg.sender, amountA);
        bool didBtransfer = tokenB.transfer(msg.sender, amountB);
        require(didAtransfer && didBtransfer, "No se pudo realizar la transferencia.");

        // Actualizo el mapeo de los balances de ambas tokens
        poolDeLiquidez[addressTokenA] = tokenA.balanceOf(address(this));
        poolDeLiquidez[addressTokenB] = tokenB.balanceOf(address(this));

        // Evento
        emit LiquidityRemoved(amountA, amountB, tokenA.balanceOf(address(this)), tokenB.balanceOf(address(this)));
    }


    function getPrice(address _token) external view returns (uint256) {
        require(_token == addressTokenA || _token == addressTokenB, "No es el address de una token.");
        if (_token == addressTokenA) {
            return (poolDeLiquidez[addressTokenB] * 10 ** 18 / poolDeLiquidez[addressTokenA]);
        }
        else {
            return (poolDeLiquidez[addressTokenA] * 10 ** 18 / poolDeLiquidez[addressTokenB]);
        }
    }

}






